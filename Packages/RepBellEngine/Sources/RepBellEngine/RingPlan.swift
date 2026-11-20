import Foundation

/// Day start and alarms that ring through silent (roadmap item 13, epic of 17 Nov 2026).
///
/// Each program day starts Ring or Quiet. On a Ring day, set alarms ring through silent and Focus. "Quiet next" on a
/// ringing alarm makes the next set a silent banner, and sets stay quiet until the person acknowledges one (taps a
/// banner, logs a set or opens the app). Dense days ring at most once every 30 minutes; the sets between are banners.
public enum DayMode: String, Codable, Sendable, Equatable {
    case ring
    case quiet
}

/// What the app keeps for day start and quiet sets. Stored on its own, apart from the run, so the run's record
/// never changes shape.
public struct RingState: Codable, Sendable, Equatable {
    /// The choice made for each date, keyed "yyyy-mm-dd".
    public var choices: [String: DayMode]
    /// When "Quiet next" was tapped. Sets after it stay quiet until an acknowledgment after this time.
    public var quietSince: CivilDateTime?
    /// The latest acknowledgment: a banner tapped, a set logged or the app opened.
    public var lastAcknowledged: CivilDateTime?

    public init(choices: [String: DayMode] = [:], quietSince: CivilDateTime? = nil, lastAcknowledged: CivilDateTime? = nil) {
        self.choices = choices
        self.quietSince = quietSince
        self.lastAcknowledged = lastAcknowledged
    }

    public static func key(_ date: CivilDate) -> String {
        String(format: "%04d-%02d-%02d", date.year, date.month, date.day)
    }

    /// The choice for a date, if one was made.
    public func choice(on date: CivilDate) -> DayMode? { choices[Self.key(date)] }

    /// The mode a day runs in: its own choice, else the latest earlier choice, else Ring on the first day.
    public func mode(on date: CivilDate) -> DayMode {
        if let own = choice(on: date) { return own }
        let earlier = choices.filter { $0.key < Self.key(date) }.max { $0.key < $1.key }
        return earlier?.value ?? .ring
    }

    /// What the day-start screen preselects: yesterday's choice carried over.
    public func preselected(on date: CivilDate) -> DayMode { mode(on: date) }

    /// Quiet is running when "Quiet next" was tapped and nothing has been acknowledged since.
    public var quietActive: Bool {
        guard let quietSince else { return false }
        guard let lastAcknowledged else { return true }
        return lastAcknowledged < quietSince
    }

    public mutating func choose(_ mode: DayMode, on date: CivilDate) {
        choices[Self.key(date)] = mode
        // Choosing for the day is an acknowledgment, so a quiet run from yesterday ends.
        quietSince = nil
    }

    public mutating func quietNext(at time: CivilDateTime) {
        quietSince = time
    }

    public mutating func acknowledge(at time: CivilDateTime) {
        lastAcknowledged = time
        if let quietSince, quietSince <= time { self.quietSince = nil }
    }

    /// Keeps only the last 30 days of choices.
    public mutating func trim(before date: CivilDate) {
        let cutoff = Self.key(date.addingDays(-30))
        choices = choices.filter { $0.key >= cutoff }
    }
}

public enum RingPlan {
    /// The least time between two ringing sets. Sets closer than this arrive as banners.
    public static let minimumGapMinutes = 30
    /// AlarmKit alarms kept scheduled ahead at once; the rest are added as the queue refills.
    public static let alarmCapacity = 12

    /// Which of today's upcoming set alerts ring, in time order.
    public static func ringing(alerts: [QueuedAlert], state: RingState, date: CivilDate) -> [QueuedAlert] {
        guard state.mode(on: date) == .ring, !state.quietActive else { return [] }
        var out: [QueuedAlert] = []
        var last: CivilDateTime?
        for alert in alerts.sorted(by: { $0.at < $1.at }) where alert.at.date == date {
            if let last, last.minutes(until: alert.at) < minimumGapMinutes { continue }
            out.append(alert)
            last = alert.at
        }
        return Array(out.prefix(alarmCapacity))
    }

    /// Whether the day-start screen should open: a program day, no choice yet today, after wake, run going.
    public static func showDayStart(run: PersistedRun?, state: RingState, now: CivilDateTime) -> Bool {
        guard let run, !run.ended, run.pausedAt == nil else { return false }
        guard let number = run.input.dayNumber(on: now.date), number <= 14 else { return false }
        guard state.choice(on: now.date) == nil else { return false }
        return now.minutes >= run.input.wake.minutesFromMidnight
    }
}
