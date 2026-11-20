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
    case paywall
    case rerun
    case studioPlayer(String)
}

/// Screens you browse to and come back from. They push onto a navigation stack with Back and swipe-back.
/// Flow screens (setup, the test, the result, the player) stay in `Screen`.
enum Browse: Hashable {
    case progress
    case settings
    case alertsCheck
    case about
    case workouts
    case workoutSettings
    case workoutSession(String)
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

        var isFinished: Bool {
            if case .finished = self { return true }
            return false
        }
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
    /// Changing the flow screen closes any browse screens on top of it.
    var screen: Screen {
        didSet { if oldValue != screen { path.removeAll() } }
    }
    var path: [Browse] = []
    var draftWake = ClockTime(hour: 7, minute: 0)
    var draftBed = ClockTime(hour: 23, minute: 0)
    var draftStartsToday = false
    var draftCount = 0
    var alertsDenied = false
    /// The date the person chose "Not yet" on the test counter. The counter doesn't open by itself again that day.
    var testDeferredOn: CivilDate?
    /// Set while the Day 15 number is being corrected from the result screen.
    var correctingDay: Int?
    /// The program day the current run was ended on, kept while the app runs for the result heading.
    private var endedOnDay: Int?
    var unlockMessage: String?
    var celebration: Celebration?

    private init() {
        let loaded = LibraryDisk.load()
        library = loaded
        screen = .promise
        screen = Self.openingScreen(for: loaded)
    }

    /// Opens a browse screen on top of the current flow screen.
    func open(_ destination: Browse) {
        path.append(destination)
    }

    /// Opens Workouts, optionally at one session, from anywhere (Today, a link, the end of a session).
    func openWorkouts(session id: String? = nil) {
        screen = library.current == nil ? .promise : .today
        var stack: [Browse] = [.workouts]
        if let id { stack.append(.workoutSession(id)) }
        path = stack
    }

    func wakeChoices() -> [ClockTime] { TimeChoices.wake }

    func bedChoices() -> [ClockTime] { TimeChoices.bed }

    func lastSetLabel() -> String {
        lastSetLabel(wake: draftWake, bed: draftBed)
    }

    func lastSetLabel(wake: ClockTime, bed: ClockTime) -> String {
        let last = ScheduleEngine.lastAllowedMinutes(bed: bed, wake: wake) % 1440
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
        await finishSetup()
    }

    /// Called when the person comes back from Settings: if notifications are now on, setup finishes by itself.
    func recheckAlerts() async {
        guard alertsDenied, library.current == nil else { return }
        if await Notifier.isAuthorized() {
            _ = await TestAlarms.authorizationGranted()
            guard alertsDenied, library.current == nil else { return }
            alertsDenied = false
            await finishSetup()
        }
    }

    /// Finishes setup without alerts. Today still shows each set when it's due.
    func startWithoutAlerts() async {
        guard library.current == nil else { return }
        await finishSetup()
    }

    private func finishSetup() async {
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
            correctingDay = nil
            draftCount = startingCount(for: day)
        }
        screen = .counter(day)
    }

    /// "Not yet" on the counter: back to Today, where the test stays ready.
    func deferTest() {
        if correctingDay != nil {
            correctingDay = nil
            screen = .result
            return
        }
        testDeferredOn = CivilDateTime.local(Date()).date
        screen = library.current == nil ? .promise : .today
    }

    /// "Fix my number" on the result: reopens the counter at the logged Day 15 number.
    func fixFinalNumber() {
        guard let run = library.current, !run.ended else { return }
        let resolved = ScheduleEngine.resolve(run.input, now: run.pausedAt ?? CivilDateTime.local(Date()))
        guard let logged = resolved.day(15)?.testReps else { return }
        correctingDay = 15
        draftCount = logged
        screen = .counter(15)
    }

    func adjustCount(by delta: Int) {
        draftCount = min(500, max(0, draftCount + delta))
    }

    func showConfirm(day: Int) {
        guard TestFlow.canSubmit(count: draftCount) else { return }
        if let correcting = correctingDay, correcting == day {
            correctingDay = nil
            var corrected = false
            update { corrected = $0.input.correctTest(day: day, reps: draftCount) }
            if corrected {
                screen = .result
                Haptics.play(.testLogged)
                return
            }
        }
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
        Haptics.play(day == 15 ? .dayComplete : .testLogged)
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

    /// When the current Busy hour ends, if one is running.
    func activeBusyEnd() -> CivilDateTime? {
        activeBusy()?.until
    }

    /// The Busy hour running now: when alerts return and how many sets it marked missed.
    func activeBusy() -> (until: CivilDateTime, skipped: Int)? {
        guard let run = library.current else { return nil }
        return ScheduleEngine.activeBusy(run.input, now: CivilDateTime.local(Date()))
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
        correctingDay = nil
        endedOnDay = nil
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

    // MARK: Studio alert hold

    /// While set, set alerts that would fire before this time are held back.
    var studioHoldUntil: Date? = UserDefaults.standard.object(forKey: "studio.holdUntil") as? Date {
        didSet { UserDefaults.standard.set(studioHoldUntil, forKey: "studio.holdUntil") }
    }

    /// Set alerts that would fire in the next so many minutes.
    func setsDuring(minutes: Int) -> Int {
        guard let run = library.current, run.pausedAt == nil, !run.ended else { return 0 }
        let now = CivilDateTime.local(Date())
        let end = Date().addingTimeInterval(TimeInterval(minutes * 60))
        let resolved = ScheduleEngine.resolve(run.input, now: now)
        return resolved.alertQueue(at: now).pending.filter { alert in
            library.allows(day: alert.day) && (alert.at.foundationDate().map { $0 < end } ?? false)
        }.count
    }

    func holdAlerts(minutes: Int) {
        studioHoldUntil = Date().addingTimeInterval(TimeInterval((minutes + 5) * 60))
        Task { await refreshAlerts() }
    }

    func releaseAlerts() {
        guard studioHoldUntil != nil else { return }
        studioHoldUntil = nil
        Task { await refreshAlerts() }
    }

    /// Whether a Workouts session waits until after Day 15 (upper-body work during a run).
    func workoutHeld(_ id: String) -> Bool {
        WorkoutRules.isHeld(id, run: library.current, now: CivilDateTime.local(Date()))
    }

    /// One Studio session to suggest, by push-up day. Upper body work is never suggested on a push day.
    func studioSuggestion() -> String {
        guard let run = library.current, !run.ended else { return "flow-45" }
        let today = CivilDateTime.local(Date()).date
        guard let day = run.input.dayNumber(on: today) else { return "flow-45" }
        switch day {
        case 1, 8, 15: return "flow-45"
        case 2, 9: return "stretch"
        default: return day % 2 == 0 ? "lower-back" : "core"
        }
    }

    // MARK: Schedule changes

    func currentWindow() -> (wake: ClockTime, bed: ClockTime)? {
        guard let run = library.current else { return nil }
        return ScheduleEngine.window(for: run.input, at: CivilDateTime.local(Date()))
    }

    func previewWindow(wake: ClockTime, bed: ClockTime) -> (before: Int, after: Int, last: ClockTime?)? {
        guard let run = library.current, !run.ended else { return nil }
        return ScheduleEngine.previewWindowChange(run.input, wake: wake, bed: bed, at: CivilDateTime.local(Date()))
    }

    /// Takes effect from now: sets already done stay, the rest of today and every later day re-space.
    func changeWindow(wake: ClockTime, bed: ClockTime) {
        let now = CivilDateTime.local(Date())
        draftWake = wake
        draftBed = bed
        update { $0.input.events.append(.window(wake: wake, bed: bed, at: now)) }
        Task { await refreshAlerts() }
    }

    // MARK: Insights

    func insightsModel() -> InsightsModel {
        let now = CivilDateTime.local(Date())
        var model = InsightsModel()
        let source = library.current ?? library.history.last
        model.runIsCurrent = library.current != nil
        if let source {
            let insights = InsightsEngine.run(source.input, now: source.pausedAt ?? now)
            model.run = insights
            var stats: [ProfileStat] = []
            if let number = source.input.dayNumber(on: (source.pausedAt ?? now).date), model.runIsCurrent {
                stats.append(ProfileStat(label: Copy.ProgressLabel.day, value: Copy.progressDay(number, ended: source.ended)))
            }
            stats.append(ProfileStat(label: Copy.ProgressLabel.pushUps, value: Copy.grouped(insights.pushUps)))
            stats.append(ProfileStat(label: Copy.ProgressLabel.setsDone, value: "\(insights.setsDone)"))
            stats.append(ProfileStat(label: Copy.ProgressLabel.setsMissed, value: "\(insights.setsMissed)"))
            if let onTime = insights.onTimePercent {
                stats.append(ProfileStat(label: Copy.ProgressLabel.onTime, value: "\(onTime)%"))
            }
            if let median = insights.medianResponseMinutes {
                stats.append(ProfileStat(label: Copy.ProgressLabel.typicalResponse, value: median == 0 ? "Instant" : "\(median) min"))
            }
            if insights.bestPerfectStreak > 0 {
                stats.append(ProfileStat(label: Copy.ProgressLabel.perfectDays, value: "\(insights.bestPerfectStreak)"))
            }
            if insights.snoozes > 0 {
                stats.append(ProfileStat(label: Copy.ProgressLabel.snoozed, value: "\(insights.snoozes)"))
            }
            model.runStats = stats
        }

        let runs = library.history + (library.current.map { [$0] } ?? [])
        if runs.count > 1 || !library.history.isEmpty {
            let totals = runs.map { InsightsEngine.run($0.input, now: $0.pausedAt ?? now) }
            let best = totals.flatMap(\.maxes).map(\.reps).max()
            model.allTime = [
                ProfileStat(label: "Push-ups", value: Copy.grouped(totals.reduce(0) { $0 + $1.pushUps })),
                ProfileStat(label: "Runs", value: "\(runs.count)"),
            ] + (best.map { [ProfileStat(label: "Best max", value: "\($0)")] } ?? [])
        }

        let log = StudioSettings.shared.log
        if !log.isEmpty {
            let minutes = log.reduce(0) { $0 + $1.minutes }
            let favorite = Dictionary(grouping: log, by: \.name).max { $0.value.count < $1.value.count }?.key
            model.studio = [
                ProfileStat(label: "Sessions", value: "\(log.count)"),
                ProfileStat(label: "Minutes", value: Copy.grouped(minutes)),
            ] + (favorite.map { [ProfileStat(label: "Most done", value: $0)] } ?? [])
        }

        model.record = library.history.reversed().map { run in
            let resolved = ScheduleEngine.resolve(run.input, now: now)
            let start = resolved.day(1)?.testReps ?? run.input.dayOneMax
            if let end = resolved.day(15)?.testReps {
                return ProfileRow(label: Self.dateLabel(run.input.start), value: "\(start) → \(end)")
            }
            return ProfileRow(label: Self.dateLabel(run.input.start), value: "\(start), ended early")
        }
        return model
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

    /// "Busy for 1 hour": one tap, no sheet. The strip on Today shows what it did and offers Undo.
    func confirmBusy() {
        let now = CivilDateTime.local(Date())
        guard activeBusyEnd() == nil else { return }
        update { $0.input.events.append(.busy(at: now)) }
        Haptics.play(.tap)
        Task { await refreshAlerts() }
    }

    func pause() {
        update { $0.pausedAt = CivilDateTime.local(Date()) }
        screen = .today
        path.removeAll()
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
        path.removeAll()
        Task { await refreshAlerts() }
    }

    /// The program day the run ended on, for the result heading.
    func endedDay() -> Int? {
        guard let run = library.current, run.ended else { return nil }
        return endedOnDay ?? run.input.lastLoggedDay
    }

    func endProgram() {
        guard var run = library.current else { return }
        endedOnDay = run.input.dayNumber(on: (run.pausedAt ?? CivilDateTime.local(Date())).date)
        run.ended = true
        run.pausedAt = nil
        library.current = run
        library.history.append(run)
        persist()
        screen = .result
        Task { await refreshAlerts() }
    }

    /// "Run it again" on the result: a review screen with the times and Tomorrow or Today.
    func reviewRerun() {
        if library.rerunNeedsUnlock {
            screen = .paywall
            return
        }
        if let window = currentWindow() {
            draftWake = window.wake
            draftBed = window.bed
        }
        screen = .rerun
    }

    /// The max the next run starts from.
    func rerunMax() -> Int {
        latestMax() ?? library.current?.input.dayOneMax ?? 0
    }

    func runAgain(startToday: Bool = false) {
        correctingDay = nil
        endedOnDay = nil
        if library.rerunNeedsUnlock {
            screen = .paywall
            return
        }
        let maxReps = rerunMax()
        let wake = draftWake
        let bed = draftBed
        if let current = library.current, !library.history.contains(where: { $0.input.start == current.input.start && $0.ended }) {
            var ended = current
            ended.ended = true
            library.history.append(ended)
        }
        library.current = nil
        draftStartsToday = startToday
        library.runsStarted += 1
        let input = Rerun.input(maxReps: maxReps, wake: wake, bed: bed, startToday: startToday, today: CivilDate.today())
        library.current = PersistedRun(input: input)
        persist()
        if startToday && CivilDateTime.local(Date()).minutes >= wake.minutesFromMidnight {
            openCounter(day: 1, preserve: false)
        } else {
            screen = .ready
        }
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
        guard Features.payment else { return }
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
        await Notifier.refill(library: library, holdUntil: studioHoldUntil.flatMap { $0 > Date() ? $0 : nil })
        if let run = library.current {
            await TestAlarms.sync(run: run, allows: { self.library.allows(day: $0) })
        } else {
            await TestAlarms.sync(run: nil, allows: { _ in false })
        }
        PhoneSessionBridge.shared.push(library)
        Notifier.scheduleRefresh()
        await PushUpHealthStore.sync(run: library.current)
    }

    func onActive() async {
        await refreshEntitlements()
        if screen == .alerts {
            await recheckAlerts()
        }
        // Only from Today or Ready itself, never over Settings or Progress (unsaved changes stay put).
        if path.isEmpty, screen == .today || screen == .ready {
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
        let now = CivilDateTime.local(Date())
        guard let number = TestFlow.counterToOpen(run: library.current, now: now, deferredOn: testDeferredOn) else { return false }
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
        if library.needsUnlock(at: CivilDateTime.local(Date())) { return .paywall }
        if run.ended { return .result }
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

struct InsightsModel {
    var run: RunInsights?
    var runIsCurrent = false
    var runStats: [ProfileStat] = []
    var allTime: [ProfileStat] = []
    var studio: [ProfileStat] = []
    var record: [ProfileRow] = []
}

extension CivilDate {
    static func today() -> CivilDate { CivilDateTime.local(Date()).date }
}
