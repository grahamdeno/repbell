import Foundation

public struct QueuedAlert: Equatable, Identifiable, Sendable {
    public var id: String { "\(day).\(index)" }
    public var day: Int
    public var index: Int
    public var reps: Int
    public var total: Int
    public var at: CivilDateTime

    public init(day: Int, index: Int, reps: Int, total: Int, at: CivilDateTime) {
        self.day = day
        self.index = index
        self.reps = reps
        self.total = total
        self.at = at
    }
}

public struct AlertQueue: Equatable, Sendable {
    public static let capacity = 60

    public var pending: [QueuedAlert]
    public var waitingForRefill: [QueuedAlert]
    public var capacity: Int

    public init(pending: [QueuedAlert], waitingForRefill: [QueuedAlert], capacity: Int) {
        self.pending = pending
        self.waitingForRefill = waitingForRefill
        self.capacity = capacity
    }
}

public enum NoteKind: String, Equatable, Codable, Sendable {
    case hardDay
    case testEve
    case endOfDay
    case dayEightFallback
}

public struct ScheduledNote: Equatable, Identifiable, Sendable {
    public var id: String
    public var kind: NoteKind
    public var at: CivilDateTime
    public var body: String

    public init(id: String, kind: NoteKind, at: CivilDateTime, body: String) {
        self.id = id
        self.kind = kind
        self.at = at
        self.body = body
    }
}

public struct ResolvedRun: Equatable, Sendable {
    public var input: RunInput
    public var days: [ScheduledDay]
    public var resolvedAt: CivilDateTime

    public func day(_ number: Int) -> ScheduledDay? {
        days.first { $0.number == number }
    }

    public var loggedSetReps: Int {
        days.filter { $0.number <= 14 }.reduce(0) { $0 + $1.loggedReps }
    }

    /// The next set that still needs a tap, if one is on the board.
    public func nextSet(at now: CivilDateTime) -> ScheduledSet? {
        let upcoming = days.flatMap(\.sets).filter { $0.status == .upcoming }
        let due = upcoming.filter { set in
            guard let alert = set.alert else { return false }
            return alert <= now
        }.sorted { $0.grid < $1.grid }
        if let first = due.first { return first }
        return upcoming.filter { ($0.alert ?? $0.grid) > now }.sorted { ($0.alert ?? $0.grid) < ($1.alert ?? $1.grid) }.first
    }

    /// At most 60 future set alerts, soonest first. The rest wait for the next refill.
    public func alertQueue(at now: CivilDateTime, capacity: Int = AlertQueue.capacity) -> AlertQueue {
        let candidates = days.flatMap { day -> [QueuedAlert] in
            day.sets.compactMap { set in
                guard set.status == .upcoming, let alert = set.alert, alert > now else { return nil }
                return QueuedAlert(day: set.day, index: set.index, reps: set.reps, total: day.sets.count, at: alert)
            }
        }.sorted { lhs, rhs in
            if lhs.at != rhs.at { return lhs.at < rhs.at }
            if lhs.day != rhs.day { return lhs.day < rhs.day }
            return lhs.index < rhs.index
        }
        return AlertQueue(
            pending: Array(candidates.prefix(capacity)),
            waitingForRefill: Array(candidates.dropFirst(capacity)),
            capacity: capacity
        )
    }

    /// Night-before, test-eve, end-of-day, and the Day 8 noon note. These use the four slots kept free of set alerts.
    public func notes() -> [ScheduledNote] {
        var notes: [ScheduledNote] = []
        if let day7 = day(7), let day8 = day(8), day8.testReps == nil, input.retestEnabled {
            let when = ScheduleEngine.evening(on: day7.date, wake: input.wake, bed: input.bed)
            notes.append(
                ScheduledNote(
                    id: "note.test.8",
                    kind: .testEve,
                    at: when,
                    body: Copy.testEve(wake: input.wake)
                )
            )
        }
        if let day8 = day(8), input.retestEnabled, day8.testReps == nil {
            let noon = CivilDateTime(date: day8.date, hour: 12, minute: 0)
            notes.append(
                ScheduledNote(
                    id: "note.fallback.8",
                    kind: .dayEightFallback,
                    at: noon,
                    body: Copy.dayEightFallback
                )
            )
        }
        if let day8 = day(8), let day9 = day(9) {
            let when = ScheduleEngine.evening(on: day8.date, wake: input.wake, bed: input.bed)
            notes.append(
                ScheduledNote(
                    id: "note.hard.9",
                    kind: .hardDay,
                    at: when,
                    body: Copy.hardDay(sets: day9.sets.count, reps: day9.reps)
                )
            )
        }
        if let day14 = day(14) {
            let when = ScheduleEngine.evening(on: day14.date, wake: input.wake, bed: input.bed)
            notes.append(
                ScheduledNote(
                    id: "note.test.15",
                    kind: .testEve,
                    at: when,
                    body: Copy.testEve(wake: input.wake)
                )
            )
        }
        for scheduled in days where scheduled.number <= 14 && !scheduled.sets.isEmpty {
            let window = ScheduleEngine.window(for: input, at: CivilDateTime(date: scheduled.date, hour: 0, minute: 0))
            let last = ScheduleEngine.lastAllowedMinutes(bed: window.bed, wake: window.wake)
            let when = CivilDateTime(date: scheduled.date, minutes: last)
            let done = scheduled.doneCount
            let missed = scheduled.missedCount
            notes.append(
                ScheduledNote(
                    id: "note.end.\(scheduled.number)",
                    kind: .endOfDay,
                    at: when,
                    body: Copy.endOfDay(done: done, total: scheduled.sets.count, reps: scheduled.loggedReps, missed: missed)
                )
            )
        }
        return notes
    }
}

public enum ScheduleEngine {
    public static let noonMinutes = 12 * 60

    public static func resolve(_ input: RunInput, now: CivilDateTime) -> ResolvedRun {
        let tests = testLog(input.events)
        let dayOneMax = tests[1]?.reps ?? input.dayOneMax
        let weekTwo = weekTwoDecision(input: input, tests: tests, dayOneMax: dayOneMax, now: now)

        var setsByDay: [Int: [ScheduledSet]] = [:]
        var days: [ScheduledDay] = []

        for number in 1...15 {
            let template = DayTemplate.day(number)
            let date = input.date(forDay: number)
            let startOfDay = CivilDateTime(date: date, hour: 0, minute: 0)
            let window = window(for: input, at: startOfDay)
            let maxUsed = number <= 7 ? dayOneMax : weekTwo.max
            let reps = RepsMath.count(max: maxUsed, relativeIntensityPercent: template.relativeIntensityPercent)
            let provisional = number >= 8 && weekTwo.provisional
            let startsAtNoon = number == 8 && weekTwo.day8StartsAtNoon
            let sets = generateSets(
                day: number,
                date: date,
                template: template,
                reps: reps,
                wake: window.wake,
                bed: window.bed,
                test: tests[number],
                startsAtNoon: startsAtNoon,
                waitingForTest: number == 8 && weekTwo.waitingForTest
            )
            setsByDay[number] = sets
            let logged = tests[number]
            days.append(
                ScheduledDay(
                    number: number,
                    date: date,
                    maxUsed: maxUsed,
                    reps: reps,
                    intervalMinutes: template.intervalMinutes,
                    isTest: template.isTest,
                    sets: sets,
                    testReps: logged?.reps,
                    testLoggedAt: logged?.at,
                    usedDayOneMax: number >= 8 && weekTwo.usedDayOneMax,
                    setsStartAtNoon: startsAtNoon,
                    weekTwoMaxIsProvisional: provisional
                )
            )
        }

        let ordered = input.events.sorted { $0.at < $1.at }
        for event in ordered {
            switch event {
            case .window(let wake, let bed, let at):
                guard let number = input.dayNumber(on: at.date) else { continue }
                let startOfDay = CivilDateTime(date: at.date, hour: 0, minute: 0)
                guard at > startOfDay else { continue }
                let template = DayTemplate.day(number)
                let reps = days[number - 1].reps
                var sets = setsByDay[number] ?? []
                applyWindowChange(
                    sets: &sets,
                    day: number,
                    date: at.date,
                    template: template,
                    reps: reps,
                    at: at,
                    wake: wake,
                    bed: bed
                )
                setsByDay[number] = sets
            case .done(let day, let index, _):
                mutate(&setsByDay, day: day, index: index) { set in
                    guard set.status == .upcoming else { return }
                    set.status = .done
                }
            case .snooze(let day, let index, _):
                applySnooze(&setsByDay, day: day, index: index, input: input)
            case .busy(let at):
                applyBusy(&setsByDay, from: at)
            case .test:
                break
            }
        }

        applyShifts(&setsByDay, shifts: input.shifts)
        applyMissed(&setsByDay, input: input, now: now)

        for index in days.indices {
            days[index].sets = setsByDay[days[index].number] ?? []
        }
        return ResolvedRun(input: input, days: days, resolvedAt: now)
    }

    public static func lastAllowedMinutes(bed: ClockTime, wake: ClockTime) -> Int {
        var bedMinutes = bed.minutesFromMidnight
        if bedMinutes <= wake.minutesFromMidnight {
            bedMinutes += 1440
        }
        return bedMinutes - 60
    }

    public static func window(for input: RunInput, at time: CivilDateTime) -> (wake: ClockTime, bed: ClockTime) {
        var wake = input.wake
        var bed = input.bed
        for event in input.events.sorted(by: { $0.at < $1.at }) {
            if case .window(let nextWake, let nextBed, let at) = event, at <= time {
                wake = nextWake
                bed = nextBed
            }
        }
        return (wake, bed)
    }

    public static func evening(on date: CivilDate, wake: ClockTime, bed: ClockTime) -> CivilDateTime {
        var bedMinutes = bed.minutesFromMidnight
        if bedMinutes <= wake.minutesFromMidnight {
            bedMinutes += 1440
        }
        let eight = 20 * 60
        let when = eight + 90 < bedMinutes ? eight : max(wake.minutesFromMidnight, bedMinutes - 90)
        return CivilDateTime(date: date, minutes: when)
    }

    // MARK: - Week 2

    private struct WeekTwo {
        var max: Int
        var usedDayOneMax: Bool
        var day8StartsAtNoon: Bool
        var waitingForTest: Bool
        var provisional: Bool
    }

    private static func weekTwoDecision(
        input: RunInput,
        tests: [Int: (reps: Int, at: CivilDateTime)],
        dayOneMax: Int,
        now: CivilDateTime
    ) -> WeekTwo {
        let day8 = input.date(forDay: 8)
        let noon = CivilDateTime(date: day8, hour: 12, minute: 0)
        if !input.retestEnabled {
            return WeekTwo(max: dayOneMax, usedDayOneMax: true, day8StartsAtNoon: true, waitingForTest: false, provisional: false)
        }
        if let test = tests[8], test.at <= noon {
            return WeekTwo(max: test.reps, usedDayOneMax: false, day8StartsAtNoon: false, waitingForTest: false, provisional: false)
        }
        if now >= noon {
            return WeekTwo(max: dayOneMax, usedDayOneMax: true, day8StartsAtNoon: true, waitingForTest: false, provisional: false)
        }
        return WeekTwo(max: dayOneMax, usedDayOneMax: false, day8StartsAtNoon: false, waitingForTest: true, provisional: true)
    }

    private static func testLog(_ events: [LogEvent]) -> [Int: (reps: Int, at: CivilDateTime)] {
        var tests: [Int: (reps: Int, at: CivilDateTime)] = [:]
        for event in events {
            if case .test(let day, let reps, let at) = event {
                if let existing = tests[day], existing.at <= at { continue }
                tests[day] = (reps, at)
            }
        }
        return tests
    }

    // MARK: - Grid

    private static func generateSets(
        day: Int,
        date: CivilDate,
        template: DayTemplate,
        reps: Int,
        wake: ClockTime,
        bed: ClockTime,
        test: (reps: Int, at: CivilDateTime)?,
        startsAtNoon: Bool,
        waitingForTest: Bool
    ) -> [ScheduledSet] {
        guard template.hasSets else { return [] }
        let last = lastAllowedMinutes(bed: bed, wake: wake)
        let first: Int?
        if template.isTest && day == 1 {
            if let test, test.at.date == date {
                first = minutesOn(test.at, relativeTo: date) + template.intervalMinutes
            } else {
                first = nil
            }
        } else if day == 8 {
            if waitingForTest {
                first = nil
            } else if let test, !startsAtNoon {
                first = minutesOn(test.at, relativeTo: date) + template.intervalMinutes
            } else if startsAtNoon {
                first = noonMinutes
            } else {
                first = nil
            }
        } else {
            first = wake.minutesFromMidnight
        }
        guard let first else { return [] }
        return grid(day: day, date: date, firstMinutes: first, interval: template.intervalMinutes, last: last, reps: reps)
    }

    private static func grid(
        day: Int,
        date: CivilDate,
        firstMinutes: Int,
        interval: Int,
        last: Int,
        reps: Int
    ) -> [ScheduledSet] {
        guard interval > 0, firstMinutes <= last else { return [] }
        var sets: [ScheduledSet] = []
        var cursor = firstMinutes
        var index = 1
        while cursor <= last && index <= 200 {
            let when = CivilDateTime(date: date, minutes: cursor)
            sets.append(
                ScheduledSet(
                    day: day,
                    index: index,
                    reps: reps,
                    grid: when,
                    alert: when,
                    status: .upcoming,
                    snoozes: 0
                )
            )
            cursor += interval
            index += 1
        }
        return sets
    }

    private static func minutesOn(_ time: CivilDateTime, relativeTo date: CivilDate) -> Int {
        (time.date.dayNumber - date.dayNumber) * 1440 + time.minutes
    }

    private static func applyWindowChange(
        sets: inout [ScheduledSet],
        day: Int,
        date: CivilDate,
        template: DayTemplate,
        reps: Int,
        at: CivilDateTime,
        wake: ClockTime,
        bed: ClockTime
    ) {
        guard template.hasSets else { return }
        let last = lastAllowedMinutes(bed: bed, wake: wake)
        let locked = sets.filter { $0.grid <= at || $0.status != .upcoming }
        if locked.isEmpty && !template.isTest {
            sets = grid(
                day: day,
                date: date,
                firstMinutes: wake.minutesFromMidnight,
                interval: template.intervalMinutes,
                last: last,
                reps: reps
            )
            return
        }
        guard let anchor = sets.map(\.grid).min() else { return }
        let interval = template.intervalMinutes
        var minute = minutesOn(anchor, relativeTo: date)
        let changeMinute = minutesOn(at, relativeTo: date)
        while minute <= changeMinute {
            minute += interval
        }
        var rebuilt = locked.sorted { $0.index < $1.index }
        var nextIndex = (rebuilt.map(\.index).max() ?? 0) + 1
        var steps = 0
        while minute <= last && steps < 200 {
            let when = CivilDateTime(date: date, minutes: minute)
            if when > at {
                rebuilt.append(
                    ScheduledSet(day: day, index: nextIndex, reps: reps, grid: when, alert: when, status: .upcoming)
                )
                nextIndex += 1
            }
            minute += interval
            steps += 1
        }
        sets = rebuilt.sorted { $0.index < $1.index }
    }

    // MARK: - Log

    private static func mutate(
        _ setsByDay: inout [Int: [ScheduledSet]],
        day: Int,
        index: Int,
        _ body: (inout ScheduledSet) -> Void
    ) {
        guard var sets = setsByDay[day], let offset = sets.firstIndex(where: { $0.index == index }) else { return }
        body(&sets[offset])
        setsByDay[day] = sets
    }

    private static func applySnooze(_ setsByDay: inout [Int: [ScheduledSet]], day: Int, index: Int, input: RunInput) {
        guard var sets = setsByDay[day], let offset = sets.firstIndex(where: { $0.index == index }) else { return }
        guard sets[offset].status == .upcoming, let alert = sets[offset].alert else { return }
        let moved = alert.adding(minutes: 10)
        let nextGrid = sets.first { $0.index == index + 1 }?.grid
        if let nextGrid, moved >= nextGrid {
            sets[offset].status = .missed
            sets[offset].alert = nil
        } else {
            let date = input.date(forDay: day)
            let window = window(for: input, at: CivilDateTime(date: date, hour: 0, minute: 0))
            let last = lastAllowedMinutes(bed: window.bed, wake: window.wake)
            let end = CivilDateTime(date: date, minutes: last)
            if moved > end {
                sets[offset].status = .missed
                sets[offset].alert = nil
            } else {
                sets[offset].alert = moved
                sets[offset].snoozes += 1
            }
        }
        setsByDay[day] = sets
    }

    private static func applyBusy(_ setsByDay: inout [Int: [ScheduledSet]], from start: CivilDateTime) {
        let end = start.adding(minutes: 60)
        for day in setsByDay.keys {
            guard var sets = setsByDay[day] else { continue }
            for index in sets.indices {
                guard sets[index].status == .upcoming, let alert = sets[index].alert else { continue }
                if alert >= start && alert < end {
                    sets[index].status = .missed
                    sets[index].alert = nil
                }
            }
            setsByDay[day] = sets
        }
    }

    private static func applyShifts(_ setsByDay: inout [Int: [ScheduledSet]], shifts: [TimeShift]) {
        for shift in shifts where shift.minutes != 0 {
            guard var sets = setsByDay[shift.day] else { continue }
            for index in sets.indices where sets[index].status == .upcoming {
                sets[index].grid = sets[index].grid.adding(minutes: shift.minutes)
                if let alert = sets[index].alert {
                    sets[index].alert = alert.adding(minutes: shift.minutes)
                }
            }
            setsByDay[shift.day] = sets
        }
    }

    private static func applyMissed(_ setsByDay: inout [Int: [ScheduledSet]], input: RunInput, now: CivilDateTime) {
        for day in 1...14 {
            guard var sets = setsByDay[day], !sets.isEmpty else { continue }
            let date = input.date(forDay: day)
            let window = window(for: input, at: CivilDateTime(date: date, hour: 0, minute: 0))
            let end = CivilDateTime(date: date, minutes: lastAllowedMinutes(bed: window.bed, wake: window.wake))
            let ordered = sets.sorted { $0.index < $1.index }
            for offset in ordered.indices {
                let current = ordered[offset]
                guard let live = sets.firstIndex(where: { $0.index == current.index }), sets[live].status == .upcoming else { continue }
                if offset + 1 < ordered.count {
                    let nextGrid = ordered[offset + 1].grid
                    if now >= nextGrid {
                        sets[live].status = .missed
                        sets[live].alert = nil
                    }
                } else if now > end {
                    sets[live].status = .missed
                    sets[live].alert = nil
                }
            }
            setsByDay[day] = sets
        }
    }
}
