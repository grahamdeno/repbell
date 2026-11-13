import Foundation
import Observation
import RepBellEngine
import UIKit

enum Screen: Equatable {
    case promise
    case wake
    case bed
    case startDay
    case alerts
    case ready
    case counter(Int)
    case confirm(day: Int, reps: Int)
    case today
    case hurts
    case result
    case about
    case paywall
    case profile
}

enum SetMark: Equatable {
    case done, missed, current, upcoming
}

struct TodaySnapshot: Equatable {
    enum Hero: Equatable {
        case waiting(eyebrow: String, time: String, title: String, detail: String)
        case test(Int)
        case next(time: String, reps: Int, line: String)
        case finished(String)
        case paused(Int)
    }

    var hero: Hero
    var eyebrow: String
    var maxText: String?
    var bars: [DayBar]
    var tallyTitle: String?
    var tallyDetail: String?
    var soFar: String?
    var marks: [SetMark]
    var showBusy: Bool
    var fallback: String?
}

@MainActor
@Observable
final class ProgramController {
    static let shared = ProgramController()

    var library: LibraryFile
    var screen: Screen
    var draftWake = ClockTime(hour: 7, minute: 0)
    var draftBed = ClockTime(hour: 23, minute: 0)
    var draftStartsToday = false
    var draftCount = 0
    var alertsDenied = false
    var unlockMessage: String?
    var showBusyConfirm = false
    var celebration: Celebration?

    private init() {
        let loaded = LibraryDisk.load()
        library = loaded
        screen = .promise
        screen = Self.openingScreen(for: loaded)
    }

    func wakeChoices() -> [ClockTime] {
        stride(from: 4 * 60, through: 11 * 60 + 30, by: 30).map { ClockTime(hour: $0 / 60, minute: $0 % 60) }
    }

    func bedChoices() -> [ClockTime] {
        stride(from: 20 * 60, through: 26 * 60, by: 30).map { minutes in
            let wrapped = minutes % 1440
            return ClockTime(hour: wrapped / 60, minute: wrapped % 60)
        }
    }

    func lastSetLabel() -> String {
        let last = ScheduleEngine.lastAllowedMinutes(bed: draftBed, wake: draftWake) % 1440
        return Copy.lastSet(at: ClockTime(hour: last / 60, minute: last % 60))
    }

    func tomorrowDetail() -> String {
        let day = weekday(CivilDate.today().addingDays(1))
        return "Test at \(Copy.clock(draftWake)), \(day)"
    }

    func todayDetail() -> String {
        let now = CivilDateTime.local(Date())
        if now.minutes >= draftWake.minutesFromMidnight {
            return "Test now; sets run until \(Copy.clock(ClockTime(hour: (ScheduleEngine.lastAllowedMinutes(bed: draftBed, wake: draftWake) % 1440) / 60, minute: ScheduleEngine.lastAllowedMinutes(bed: draftBed, wake: draftWake) % 60)))."
        }
        return "Test at \(Copy.clock(draftWake)), \(weekday(CivilDate.today()))"
    }

    func allowAlerts() async {
        let notes = await Notifier.requestAuthorization()
        _ = await TestAlarms.authorizationGranted()
        alertsDenied = !notes
        guard notes else { return }
        createRun(startToday: draftStartsToday)
        if draftStartsToday && CivilDateTime.local(Date()).minutes >= draftWake.minutesFromMidnight {
            openCounter(day: 1, preserve: false)
        } else {
            screen = .ready
            Haptics.play(.dayComplete)
        }
        await refreshAlerts()
    }

    func finishReady() {
        if jumpToFreshTest() {
            return
        }
        screen = .today
    }

    func openCounter(day: Int, preserve: Bool) {
        if !preserve {
            draftCount = startingCount(for: day)
        }
        screen = .counter(day)
    }

    func adjustCount(by delta: Int) {
        draftCount = min(500, max(0, draftCount + delta))
    }

    func showConfirm(day: Int) {
        guard draftCount >= 1 else { return }
        if day == 15 {
            commitTest(day: day, reps: draftCount)
            return
        }
        screen = .confirm(day: day, reps: draftCount)
    }

    func confirmPreview(day: Int, reps: Int) -> ScheduledDay? {
        guard var run = library.current else { return nil }
        let now = CivilDateTime.local(Date())
        run.input.events.append(.test(day: day, reps: reps, at: now))
        if day == 1 { run.input.dayOneMax = reps }
        return ScheduleEngine.resolve(run.input, now: now).day(day)
    }

    func commitTest(day: Int, reps: Int) {
        let now = CivilDateTime.local(Date())
        update { run in
            run.input.events.append(.test(day: day, reps: reps, at: now))
            if day == 1 { run.input.dayOneMax = reps }
        }
        screen = day == 15 ? .result : .today
        Haptics.play(day == 15 ? .result : .testLogged)
        Task { await refreshAlerts() }
    }

    func logDone(day: Int, index: Int, celebrate: Bool = false) {
        let now = CivilDateTime.local(Date())
        update { $0.input.events.append(.done(day: day, index: index, at: now)) }
        if let run = library.current, let resolved = ScheduleEngine.resolve(run.input, now: now).day(day) {
            let finished = !resolved.sets.isEmpty && !resolved.sets.contains { $0.status == .upcoming }
            Haptics.play(finished ? .dayComplete : .setDone)
            if celebrate {
                let reps = resolved.sets.first { $0.index == index }?.reps ?? resolved.reps
                celebration = Celebration(day: day, reps: reps, done: resolved.doneCount, total: resolved.sets.count, repsToday: resolved.loggedReps, dayComplete: finished)
            }
        }
        Task { await refreshAlerts() }
    }

    /// The set that is due right now, if any.
    func dueSet() -> ScheduledSet? {
        guard let run = library.current, run.pausedAt == nil, !run.ended else { return nil }
        let now = CivilDateTime.local(Date())
        guard let next = ScheduleEngine.resolve(run.input, now: now).nextSet(at: now), let alert = next.alert, alert <= now else { return nil }
        guard library.allows(day: next.day) else { return nil }
        return next
    }

    /// Upcoming sets whose alerts fall in the next hour; these are the ones Busy would skip.
    func setsInNextHour() -> [ScheduledSet] {
        guard let run = library.current else { return [] }
        let now = CivilDateTime.local(Date())
        let end = now.adding(minutes: 60)
        return ScheduleEngine.resolve(run.input, now: now).days.flatMap(\.sets).filter { set in
            guard set.status == .upcoming, let alert = set.alert else { return false }
            return alert >= now && alert < end
        }.sorted { $0.grid < $1.grid }
    }

    /// When the current Busy hour ends, if one is running.
    func activeBusyEnd() -> CivilDateTime? {
        guard let run = library.current else { return nil }
        let now = CivilDateTime.local(Date())
        for event in run.input.events.reversed() {
            if case .busy(let at) = event {
                let end = at.adding(minutes: 60)
                return end > now ? end : nil
            }
        }
        return nil
    }

    func undoBusy() {
        guard activeBusyEnd() != nil, var run = library.current else { return }
        if let index = run.input.events.lastIndex(where: { if case .busy = $0 { return true } else { return false } }) {
            run.input.events.remove(at: index)
            library.current = run
            persist()
            Haptics.play(.tap)
            Task { await refreshAlerts() }
        }
    }

    func startOver() {
        let now = CivilDateTime.local(Date())
        if let run = library.current {
            let resolved = ScheduleEngine.resolve(run.input, now: run.pausedAt ?? now)
            if resolved.day(1)?.testReps != nil, !library.history.contains(where: { $0.input.start == run.input.start }) {
                var ended = run
                ended.ended = true
                ended.pausedAt = nil
                library.history.append(ended)
            }
            let reachedDay = run.input.dayNumber(on: (run.pausedAt ?? now).date) ?? 0
            if library.runsStarted <= 1 && reachedDay <= 3 {
                // Restarting the first run inside its free days keeps those days free.
                library.runsStarted = 0
            }
            draftWake = run.input.wake
            draftBed = run.input.bed
        }
        library.current = nil
        draftStartsToday = false
        draftCount = 0
        persist()
        screen = .promise
        Task { await refreshAlerts() }
    }

    func restorePurchases() async {
        let found = await Unlocker.restore()
        if found {
            library.unlocked = true
            unlockMessage = nil
            persist()
            Haptics.play(.dayComplete)
        } else {
            unlockMessage = Copy.restoreNone
        }
    }

    func profileSnapshot() -> ProfileSnapshot {
        let now = CivilDateTime.local(Date())
        var runRows: [ProfileRow] = []
        var schedule: [ProfileRow] = []
        if let run = library.current {
            let moment = run.pausedAt ?? now
            let resolved = ScheduleEngine.resolve(run.input, now: moment)
            if let number = run.input.dayNumber(on: moment.date) {
                runRows.append(ProfileRow(label: "Day", value: run.ended ? "Ended" : "\(min(number, 15)) of 14"))
            } else if moment.date < run.input.start {
                runRows.append(ProfileRow(label: "Day", value: "Starts \(Self.dateLabel(run.input.start))"))
            }
            runRows.append(ProfileRow(label: "Started", value: Self.dateLabel(run.input.start)))
            let max = resolved.day(15)?.testReps ?? resolved.day(8)?.testReps ?? resolved.day(1)?.testReps
            runRows.append(ProfileRow(label: "Max", value: max.map(String.init) ?? "Test on Day 1"))
            runRows.append(ProfileRow(label: "Push-ups", value: Copy.grouped(resolved.loggedSetReps)))
            schedule.append(ProfileRow(label: "Wake", value: Copy.clock(run.input.wake)))
            schedule.append(ProfileRow(label: "Bed", value: Copy.clock(run.input.bed)))
            let last = ScheduleEngine.lastAllowedMinutes(bed: run.input.bed, wake: run.input.wake) % 1440
            schedule.append(ProfileRow(label: "Last set", value: Copy.clock(ClockTime(hour: last / 60, minute: last % 60))))
            schedule.append(ProfileRow(label: "Week 2 re-test", value: run.input.retestEnabled ? "On" : "Off"))
        }
        let record: [ProfileRow] = library.history.reversed().map { run in
            let resolved = ScheduleEngine.resolve(run.input, now: now)
            let start = resolved.day(1)?.testReps ?? run.input.dayOneMax
            if let end = resolved.day(15)?.testReps {
                return ProfileRow(label: Self.dateLabel(run.input.start), value: "\(start) → \(end)")
            }
            return ProfileRow(label: Self.dateLabel(run.input.start), value: "\(start), ended early")
        }
        return ProfileSnapshot(run: runRows, record: record, schedule: schedule, unlocked: library.unlocked)
    }

    static func dateLabel(_ date: CivilDate) -> String {
        let calendar = Calendar.current
        guard let foundation = calendar.date(from: DateComponents(year: date.year, month: date.month, day: date.day)) else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: foundation)
    }

    func logSnooze(day: Int, index: Int) {
        let now = CivilDateTime.local(Date())
        update { $0.input.events.append(.snooze(day: day, index: index, at: now)) }
        Task { await refreshAlerts() }
    }

    func confirmBusy() {
        let now = CivilDateTime.local(Date())
        showBusyConfirm = false
        update { $0.input.events.append(.busy(at: now)) }
        Haptics.play(.tap)
        Task { await refreshAlerts() }
    }

    func busyUntil() -> CivilDateTime {
        CivilDateTime.local(Date()).adding(minutes: 60)
    }

    func pause() {
        update { $0.pausedAt = CivilDateTime.local(Date()) }
        screen = .today
        Task { await refreshAlerts() }
    }

    func resume() {
        guard let paused = library.current?.pausedAt, var run = library.current else { return }
        let now = CivilDateTime.local(Date())
        let dayGap = now.date.dayNumber - paused.date.dayNumber
        let minuteSlide = now.minutes - paused.minutes
        let programDay = run.input.dayNumber(on: paused.date) ?? 1
        if dayGap > 0 {
            run.input.start = run.input.start.addingDays(dayGap)
            run.input.events = run.input.events.map { $0.adding(days: dayGap) }
        }
        if minuteSlide != 0 {
            run.input.shifts.append(TimeShift(day: programDay, minutes: minuteSlide))
        }
        run.pausedAt = nil
        library.current = run
        persist()
        screen = .today
        Task { await refreshAlerts() }
    }

    func endProgram() {
        guard var run = library.current else { return }
        run.ended = true
        run.pausedAt = nil
        library.current = run
        library.history.append(run)
        persist()
        screen = .result
        Task { await refreshAlerts() }
    }

    func runAgain() {
        guard library.unlocked else {
            screen = .paywall
            return
        }
        let maxReps = latestMax() ?? library.current?.input.dayOneMax ?? 0
        let wake = library.current?.input.wake ?? draftWake
        let bed = library.current?.input.bed ?? draftBed
        if let current = library.current, !library.history.contains(where: { $0.input.start == current.input.start && $0.ended }) {
            var ended = current
            ended.ended = true
            library.history.append(ended)
        }
        library.current = nil
        draftWake = wake
        draftBed = bed
        draftStartsToday = false
        library.runsStarted += 1
        let input = RunInput(dayOneMax: maxReps, wake: wake, bed: bed, start: CivilDate.today().addingDays(1), retestEnabled: true)
        library.current = PersistedRun(input: input)
        persist()
        screen = .ready
        Task { await refreshAlerts() }
    }

    func purchaseUnlock() async {
        let bought = await Unlocker.purchase()
        if bought {
            library.unlocked = true
            unlockMessage = nil
            persist()
            screen = library.current == nil ? .promise : .today
            Haptics.play(.result)
            await refreshAlerts()
        } else if unlockMessage == nil {
            unlockMessage = Copy.unlockMissing
        }
    }

    func refreshEntitlements() async {
        if await Unlocker.hasUnlock() {
            library.unlocked = true
            persist()
        }
    }

    func handleNotification(action: String, identifier: String) {
        let parts = identifier.split(separator: ".")
        guard parts.count == 3, parts[0] == "set", let day = Int(parts[1]), let index = Int(parts[2]) else { return }
        if action == Notifier.doneAction {
            logDone(day: day, index: index)
        } else if action == Notifier.laterAction {
            logSnooze(day: day, index: index)
        }
    }

    /// Many screens ask for a refresh at once (open, log, busy). Each refresh waits for the one before it
    /// and reads the library when it actually runs, so two refills can never undo each other.
    private var alertRefreshTail: Task<Void, Never>?

    func refreshAlerts() async {
        let previous = alertRefreshTail
        let task = Task { @MainActor in
            await previous?.value
            await self.performAlertRefresh()
        }
        alertRefreshTail = task
        await task.value
    }

    private func performAlertRefresh() async {
        await Notifier.refill(library: library)
        if let run = library.current {
            await TestAlarms.sync(run: run, allows: { self.library.allows(day: $0) })
        } else {
            await TestAlarms.sync(run: nil, allows: { _ in false })
        }
        PhoneSessionBridge.shared.push(library)
        Notifier.scheduleRefresh()
    }

    func onActive() async {
        await refreshEntitlements()
        if screen == .today || screen == .ready {
            if jumpToFreshTest() { return }
        }
        await refreshAlerts()
    }

    func todaySnapshot() -> TodaySnapshot {
        let now = CivilDateTime.local(Date())
        guard let run = library.current else {
            return TodaySnapshot(hero: .waiting(eyebrow: "", time: "", title: "", detail: ""), eyebrow: "", maxText: nil, bars: Array(repeating: .future, count: 14), tallyTitle: nil, tallyDetail: nil, soFar: nil, marks: [], showBusy: false, fallback: nil)
        }
        if run.pausedAt != nil {
            let day = run.input.dayNumber(on: run.pausedAt!.date) ?? 1
            let resolved = ScheduleEngine.resolve(run.input, now: run.pausedAt!)
            return snapshot(resolved: resolved, run: run, now: run.pausedAt!, hero: .paused(day))
        }
        if run.ended {
            return snapshot(resolved: ScheduleEngine.resolve(run.input, now: now), run: run, now: now, hero: .finished(Copy.endDetail))
        }
        let programNow = now
        guard let number = run.input.dayNumber(on: programNow.date) else {
            if programNow.date < run.input.start {
                return TodaySnapshot(
                    hero: .waiting(
                        eyebrow: Copy.setupReady(when: "tomorrow"),
                        time: Copy.hourMinute(run.input.wake),
                        title: Copy.withYourTest,
                        detail: Copy.nothingElse
                    ),
                    eyebrow: Copy.setupReady(when: "tomorrow"),
                    maxText: nil,
                    bars: Array(repeating: .future, count: 14),
                    tallyTitle: nil,
                    tallyDetail: nil,
                    soFar: nil,
                    marks: [],
                    showBusy: false,
                    fallback: nil
                )
            }
            return snapshot(resolved: ScheduleEngine.resolve(run.input, now: now), run: run, now: now, hero: .finished(Copy.endDetail))
        }
        if !library.allows(day: number) {
            return TodaySnapshot(hero: .waiting(eyebrow: "", time: "", title: "", detail: ""), eyebrow: "", maxText: nil, bars: [], tallyTitle: nil, tallyDetail: nil, soFar: nil, marks: [], showBusy: false, fallback: nil)
        }
        let resolved = ScheduleEngine.resolve(run.input, now: now)
        guard let day = resolved.day(number) else {
            return snapshot(resolved: resolved, run: run, now: now, hero: .finished(""))
        }
        if day.isTest && day.testReps == nil && programNow.minutes < run.input.wake.minutesFromMidnight && programNow.date == run.input.start {
            return TodaySnapshot(
                hero: .waiting(
                    eyebrow: Copy.setupReady(when: "today"),
                    time: Copy.hourMinute(run.input.wake),
                    title: Copy.withYourTest,
                    detail: Copy.nothingElse
                ),
                eyebrow: Copy.dayProgress(1),
                maxText: nil,
                bars: (1...14).map { $0 == 1 ? .today : .future },
                tallyTitle: nil,
                tallyDetail: nil,
                soFar: nil,
                marks: [],
                showBusy: false,
                fallback: nil
            )
        }
        if day.isTest && day.testReps == nil {
            return snapshot(resolved: resolved, run: run, now: now, hero: .test(number))
        }
        if let next = day.sets.first(where: { $0.status == .upcoming }), let alert = next.alert {
            let minutes = Copy.minutesUntil(alert, from: now)
            let line = minutes == 0 ? "push-ups now" : Copy.pushUpsIn(minutes: minutes)
            return snapshot(resolved: resolved, run: run, now: now, hero: .next(time: Copy.nextSetTime(alert), reps: next.reps, line: line))
        }
        if day.sets.isEmpty && day.isTest {
            return snapshot(resolved: resolved, run: run, now: now, hero: .test(number))
        }
        let line = Copy.endOfDay(done: day.doneCount, total: day.sets.count, reps: day.loggedReps, missed: day.missedCount)
        return snapshot(resolved: resolved, run: run, now: now, hero: .finished(line))
    }

    func resultNumbers() -> (start: Int, end: Int?, reps: Int, percent: Int?) {
        let now = library.current?.pausedAt ?? CivilDateTime.local(Date())
        let resolved = library.current.map { ScheduleEngine.resolve($0.input, now: now) }
        let start = resolved?.day(1)?.testReps ?? library.current?.input.dayOneMax ?? 0
        let end = resolved?.day(15)?.testReps
        let reps = resolved?.loggedSetReps ?? 0
        let percent = end.map { Copy.percentGain(from: start, to: $0) }
        return (start, end, reps, percent)
    }

    func applyWatch(_ info: [String: Any]) {
        guard let kind = info["kind"] as? String else { return }
        let day = info["day"] as? Int ?? 0
        let index = info["index"] as? Int ?? 0
        switch kind {
        case "done": logDone(day: day, index: index)
        case "snooze": logSnooze(day: day, index: index)
        case "busy": confirmBusy()
        default: break
        }
    }

    private func createRun(startToday: Bool) {
        if library.current != nil {
            return
        }
        library.runsStarted += 1
        let start = startToday ? CivilDate.today() : CivilDate.today().addingDays(1)
        let input = RunInput(dayOneMax: 0, wake: draftWake, bed: draftBed, start: start, retestEnabled: true)
        library.current = PersistedRun(input: input)
        persist()
    }

    private func update(_ body: (inout PersistedRun) -> Void) {
        guard var run = library.current else { return }
        body(&run)
        library.current = run
        persist()
    }

    private func persist() {
        LibraryDisk.save(library)
        PhoneSessionBridge.shared.push(library)
    }

    private func startingCount(for day: Int) -> Int {
        guard let run = library.current else { return 0 }
        let resolved = ScheduleEngine.resolve(run.input, now: CivilDateTime.local(Date()))
        if day == 8 { return resolved.day(1)?.testReps ?? run.input.dayOneMax }
        if day == 15 { return resolved.day(8)?.testReps ?? resolved.day(1)?.testReps ?? run.input.dayOneMax }
        return 0
    }

    @discardableResult
    private func jumpToFreshTest() -> Bool {
        guard let run = library.current, !run.ended, run.pausedAt == nil else { return false }
        let now = CivilDateTime.local(Date())
        guard let number = run.input.dayNumber(on: now.date) else { return false }
        let template = DayTemplate.day(number)
        guard template.isTest else { return false }
        let resolved = ScheduleEngine.resolve(run.input, now: now)
        guard resolved.day(number)?.testReps == nil else { return false }
        let wakeMinutes = run.input.wake.minutesFromMidnight
        let delta = now.minutes - wakeMinutes
        guard delta >= 0 && delta <= 90 else { return false }
        openCounter(day: number, preserve: false)
        return true
    }

    private func latestMax() -> Int? {
        let now = CivilDateTime.local(Date())
        guard let run = library.current else { return nil }
        let resolved = ScheduleEngine.resolve(run.input, now: now)
        return resolved.day(15)?.testReps ?? resolved.day(8)?.testReps ?? resolved.day(1)?.testReps
    }

    private func snapshot(resolved: ResolvedRun, run: PersistedRun, now: CivilDateTime, hero: TodaySnapshot.Hero) -> TodaySnapshot {
        let number = run.input.dayNumber(on: now.date)
        let day = number.flatMap { resolved.day($0) }
        let bars: [DayBar] = (1...14).map { index in
            guard let number else { return now.date < run.input.start ? .future : .past }
            if index < number { return .past }
            if index == number { return .today }
            return .future
        }
        let marks: [SetMark]
        if let day {
            if let current = day.sets.first(where: { $0.status == .upcoming })?.index {
                marks = day.sets.map { set in
                    if set.status == .done { return .done }
                    if set.status == .missed { return .missed }
                    if set.index == current { return .current }
                    return .upcoming
                }
            } else {
                marks = day.sets.map { $0.status == .missed ? .missed : .done }
            }
        } else {
            marks = []
        }
        let eyebrow = number.map { Copy.dayProgress(min($0, 14)) } ?? Copy.setupReady(when: "tomorrow")
        let fallback = (day?.number == 8 && day?.usedDayOneMax == true) ? Copy.dayEightFallback : nil
        return TodaySnapshot(
            hero: hero,
            eyebrow: eyebrow,
            maxText: day.map { Copy.maxLabel($0.maxUsed) },
            bars: bars,
            tallyTitle: day == nil || day?.sets.isEmpty == true ? nil : Copy.todaysSets,
            tallyDetail: day.map { Copy.tally(done: $0.doneCount, total: $0.sets.count, missed: $0.missedCount) },
            soFar: day.map { Copy.repsSoFar($0.loggedReps) },
            marks: marks,
            showBusy: day?.sets.contains { $0.status == .upcoming } == true && run.pausedAt == nil && !run.ended,
            fallback: fallback
        )
    }

    private static func openingScreen(for library: LibraryFile) -> Screen {
        guard let run = library.current else { return .promise }
        if !library.unlocked && !library.isFirstRun && !run.ended { return .paywall }
        if run.ended { return .result }
        let now = run.pausedAt ?? CivilDateTime.local(Date())
        if let number = run.input.dayNumber(on: now.date), !library.allows(day: number), run.pausedAt == nil {
            return .paywall
        }
        return .today
    }

    private func weekday(_ date: CivilDate) -> String {
        var calendar = Calendar.current
        guard let foundation = calendar.date(from: DateComponents(year: date.year, month: date.month, day: date.day)) else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: foundation)
    }
}

struct Celebration: Equatable, Identifiable {
    var id: String { "\(day).\(done)" }
    var day: Int
    var reps: Int
    var done: Int
    var total: Int
    var repsToday: Int
    var dayComplete: Bool
}

struct ProfileRow: Identifiable, Equatable {
    var id: String { label + value }
    var label: String
    var value: String
}

struct ProfileSnapshot: Equatable {
    var run: [ProfileRow]
    var record: [ProfileRow]
    var schedule: [ProfileRow]
    var unlocked: Bool
}

extension CivilDate {
    static func today() -> CivilDate { CivilDateTime.local(Date()).date }
}
