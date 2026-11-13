import Foundation

/// One day of the 14-day program, plus the Day 15 test. Numbers are the published RI and SF.
public struct DayTemplate: Equatable, Sendable {
    public let number: Int
    public let relativeIntensityPercent: Int
    public let intervalMinutes: Int
    public let isTest: Bool

    public var hasSets: Bool { intervalMinutes > 0 && relativeIntensityPercent > 0 }

    public static let all: [DayTemplate] = [
        DayTemplate(number: 1, relativeIntensityPercent: 30, intervalMinutes: 60, isTest: true),
        DayTemplate(number: 2, relativeIntensityPercent: 50, intervalMinutes: 60, isTest: false),
        DayTemplate(number: 3, relativeIntensityPercent: 60, intervalMinutes: 45, isTest: false),
        DayTemplate(number: 4, relativeIntensityPercent: 25, intervalMinutes: 60, isTest: false),
        DayTemplate(number: 5, relativeIntensityPercent: 45, intervalMinutes: 30, isTest: false),
        DayTemplate(number: 6, relativeIntensityPercent: 40, intervalMinutes: 60, isTest: false),
        DayTemplate(number: 7, relativeIntensityPercent: 20, intervalMinutes: 90, isTest: false),
        DayTemplate(number: 8, relativeIntensityPercent: 35, intervalMinutes: 45, isTest: true),
        DayTemplate(number: 9, relativeIntensityPercent: 55, intervalMinutes: 20, isTest: false),
        DayTemplate(number: 10, relativeIntensityPercent: 30, intervalMinutes: 15, isTest: false),
        DayTemplate(number: 11, relativeIntensityPercent: 65, intervalMinutes: 60, isTest: false),
        DayTemplate(number: 12, relativeIntensityPercent: 35, intervalMinutes: 45, isTest: false),
        DayTemplate(number: 13, relativeIntensityPercent: 45, intervalMinutes: 60, isTest: false),
        DayTemplate(number: 14, relativeIntensityPercent: 25, intervalMinutes: 120, isTest: false),
        DayTemplate(number: 15, relativeIntensityPercent: 0, intervalMinutes: 0, isTest: true)
    ]

    public static func day(_ number: Int) -> DayTemplate {
        precondition((1...15).contains(number))
        return all[number - 1]
    }
}

public enum RepsMath {
    /// RI × max, rounded up, at least 1. Whole numbers only: `(max × RI% + 99) / 100`.
    public static func count(max pushUpMax: Int, relativeIntensityPercent: Int) -> Int {
        guard pushUpMax > 0, relativeIntensityPercent > 0 else { return 0 }
        return Swift.max(1, (pushUpMax * relativeIntensityPercent + 99) / 100)
    }
}

public enum SetStatus: String, Equatable, Codable, Sendable {
    case upcoming
    case done
    case missed
}

public struct ScheduledSet: Equatable, Identifiable, Sendable {
    public var id: String { "\(day).\(index)" }
    public var day: Int
    public var index: Int
    public var reps: Int
    /// Original grid time. Snooze and pause never move this for other sets.
    public var grid: CivilDateTime
    /// When the alert fires. Nil once the set is missed or has no alert.
    public var alert: CivilDateTime?
    public var status: SetStatus
    public var snoozes: Int

    public init(
        day: Int,
        index: Int,
        reps: Int,
        grid: CivilDateTime,
        alert: CivilDateTime?,
        status: SetStatus,
        snoozes: Int = 0
    ) {
        self.day = day
        self.index = index
        self.reps = reps
        self.grid = grid
        self.alert = alert
        self.status = status
        self.snoozes = snoozes
    }
}

public struct ScheduledDay: Equatable, Sendable {
    public var number: Int
    public var date: CivilDate
    public var maxUsed: Int
    public var reps: Int
    public var intervalMinutes: Int
    public var isTest: Bool
    public var sets: [ScheduledSet]
    public var testReps: Int?
    public var testLoggedAt: CivilDateTime?
    /// Week 2 is on the Day 1 max because re-test is off, or Day 8 was not logged by noon.
    public var usedDayOneMax: Bool
    public var setsStartAtNoon: Bool
    /// Re-test is still on and Day 8 has not been decided, so week 2 reps may change.
    public var weekTwoMaxIsProvisional: Bool

    public var doneCount: Int { sets.filter { $0.status == .done }.count }
    public var missedCount: Int { sets.filter { $0.status == .missed }.count }
    public var loggedReps: Int { sets.filter { $0.status == .done }.reduce(0) { $0 + $1.reps } }

    public func set(_ index: Int) -> ScheduledSet? {
        sets.first { $0.index == index }
    }
}

public struct TimeShift: Equatable, Codable, Sendable {
    /// Program day whose still-upcoming sets move forward. Other days stay on the grid.
    public var day: Int
    public var minutes: Int

    public init(day: Int, minutes: Int) {
        self.day = day
        self.minutes = minutes
    }
}

public enum LogEvent: Equatable, Codable, Sendable {
    case test(day: Int, reps: Int, at: CivilDateTime)
    case done(day: Int, index: Int, at: CivilDateTime)
    case snooze(day: Int, index: Int, at: CivilDateTime)
    case busy(at: CivilDateTime)
    case window(wake: ClockTime, bed: ClockTime, at: CivilDateTime)

    public var at: CivilDateTime {
        switch self {
        case .test(_, _, let at),
             .done(_, _, let at),
             .snooze(_, _, let at),
             .busy(let at),
             .window(_, _, let at):
            return at
        }
    }

    /// Move the timestamp by whole calendar days. The program day numbers stay put.
    public func adding(days: Int) -> LogEvent {
        guard days != 0 else { return self }
        let moved = CivilDateTime(date: at.date.addingDays(days), minutes: at.minutes)
        switch self {
        case .test(let day, let reps, _):
            return .test(day: day, reps: reps, at: moved)
        case .done(let day, let index, _):
            return .done(day: day, index: index, at: moved)
        case .snooze(let day, let index, _):
            return .snooze(day: day, index: index, at: moved)
        case .busy:
            return .busy(at: moved)
        case .window(let wake, let bed, _):
            return .window(wake: wake, bed: bed, at: moved)
        }
    }
}

public struct RunInput: Equatable, Codable, Sendable {
    public var dayOneMax: Int
    public var wake: ClockTime
    public var bed: ClockTime
    public var start: CivilDate
    public var retestEnabled: Bool
    public var events: [LogEvent]
    /// Pause shifts. Empty unless the program was paused and resumed.
    public var shifts: [TimeShift]

    public init(
        dayOneMax: Int,
        wake: ClockTime,
        bed: ClockTime,
        start: CivilDate,
        retestEnabled: Bool = true,
        events: [LogEvent] = [],
        shifts: [TimeShift] = []
    ) {
        self.dayOneMax = dayOneMax
        self.wake = wake
        self.bed = bed
        self.start = start
        self.retestEnabled = retestEnabled
        self.events = events
        self.shifts = shifts
    }

    public func date(forDay number: Int) -> CivilDate {
        start.addingDays(number - 1)
    }

    public func dayNumber(on date: CivilDate) -> Int? {
        let delta = date.dayNumber - start.dayNumber
        let number = delta + 1
        guard (1...15).contains(number) else { return nil }
        return number
    }
}
