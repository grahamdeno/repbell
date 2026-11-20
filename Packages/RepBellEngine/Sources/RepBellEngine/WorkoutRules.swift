/// Rules that keep Workouts from competing with the push-up program (Build E).
public enum WorkoutRules {
    /// Sessions with upper-body pushing or pulling. The program asks for no other upper-body training
    /// during the 14 days, so these wait until after the final test.
    public static let upperBody: Set<String> = ["upper", "shoulders-arms", "kettlebell", "grip-pull"]

    /// Whether a run is in its 14 program days (paused counts; ended or not yet started doesn't).
    public static func runIsActive(_ run: PersistedRun?, now: CivilDateTime) -> Bool {
        guard let run, !run.ended else { return false }
        let moment = run.pausedAt ?? now
        guard let day = run.input.dayNumber(on: moment.date) else { return false }
        return day <= 14
    }

    /// Whether a session waits until after Day 15.
    public static func isHeld(_ sessionID: String, run: PersistedRun?, now: CivilDateTime) -> Bool {
        upperBody.contains(sessionID) && runIsActive(run, now: now)
    }
}

/// Push-ups to Apple Health (roadmap item 12): one workout per finished program day, written once.
public enum PushUpHealth {
    public struct Day: Equatable, Sendable {
        public let key: String
        public let day: Int
        public let pushUps: Int
        public let sets: Int
        /// When the last set that day was logged.
        public let end: CivilDateTime
        /// One minute per set done, ending at `end`.
        public var minutes: Int { max(1, sets) }
    }

    /// The days to write now: finished (the day is over or nothing is left), at least one set done, not written yet.
    public static func pending(run: PersistedRun?, now: CivilDateTime, written: Set<String>) -> [Day] {
        guard let run else { return [] }
        let resolved = ScheduleEngine.resolve(run.input, now: run.pausedAt ?? now)
        var doneAt: [String: CivilDateTime] = [:]
        for event in run.input.events {
            if case .done(let day, let index, let at) = event { doneAt["\(day).\(index)"] = at }
        }
        var out: [Day] = []
        for day in resolved.days where day.number <= 14 {
            let finished = !day.sets.isEmpty && !day.sets.contains { $0.status == .upcoming }
            let isPast = day.date < now.date
            guard finished || isPast else { continue }
            let done = day.sets.filter { $0.status == .done }
            guard !done.isEmpty else { continue }
            let key = "\(run.input.start.year)-\(run.input.start.month)-\(run.input.start.day).\(day.number)"
            guard !written.contains(key) else { continue }
            let end = done.compactMap { doneAt[$0.id] }.max() ?? done.map(\.grid).max() ?? now
            out.append(Day(key: key, day: day.number, pushUps: day.loggedReps, sets: done.count, end: end))
        }
        return out
    }
}
