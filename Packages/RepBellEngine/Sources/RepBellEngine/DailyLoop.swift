/// Rules for the daily loop that Today, the widget and the counter follow. Kept here so they are unit tested.

/// How long the in-app celebration stays when nobody taps (roadmap item 2).
public enum CelebrationTiming {
    public static let perSet: Double = 1.5
    public static let dayComplete: Double = 4.0

    /// Seconds before it dismisses itself, or nil to wait for a tap. With VoiceOver on it waits, so it can be read.
    /// With a coach line showing it also waits: the person clears it, and only then does a desk stretch come up.
    public static func autoDismiss(dayComplete: Bool, voiceOverRunning: Bool, coachLine: Bool = false) -> Double? {
        if voiceOverRunning || coachLine { return nil }
        return dayComplete ? Self.dayComplete : perSet
    }
}

/// The haptic pattern for a finished day and Day 15: bursts that build from light to strong and ease back.
public enum CelebrationHaptics {
    public struct Hit: Equatable, Sendable {
        public let time: Double
        public let intensity: Double
    }

    /// Five bursts of three taps. Intensity rises to the third burst and falls after it.
    public static func dayComplete() -> [Hit] {
        let levels: [Double] = [0.35, 0.65, 1.0, 0.65, 0.35]
        var hits: [Hit] = []
        for (burst, level) in levels.enumerated() {
            let start = Double(burst) * 0.5
            for tap in 0..<3 {
                hits.append(Hit(time: start + Double(tap) * 0.08, intensity: level))
            }
        }
        return hits
    }
}

/// The slide-to-set counter. Short strokes move one rep at a time; long, fast strokes speed up (UX-14).
public enum CounterMath {
    public static let pointsPerRep: Double = 14

    /// Reps for a drag of `points` (positive is up). The first 6 reps are exact; past that each point counts for more.
    public static func reps(forDrag points: Double) -> Int {
        let steps = abs(points) / pointsPerRep
        let exact = 6.0
        let value = steps <= exact ? steps : exact + (steps - exact) * (1 + (steps - exact) / 12)
        let rounded = Int(value.rounded())
        return points < 0 ? -rounded : rounded
    }
}

/// What the widget shows (UX-15).
public enum WidgetState: Equatable, Sendable {
    case notStarted
    case startsOn(wake: ClockTime)
    case testToday(day: Int, wake: ClockTime)
    case next(day: Int, at: CivilDateTime, reps: Int)
    case dayDone(day: Int, done: Int, total: Int, reps: Int)
    case paused(day: Int)
    case finished

    public static func make(run: PersistedRun?, now: CivilDateTime) -> WidgetState {
        guard let run else { return .notStarted }
        if run.ended { return .finished }
        let moment = run.pausedAt ?? now
        if run.pausedAt != nil {
            return .paused(day: run.input.dayNumber(on: moment.date) ?? 1)
        }
        guard let number = run.input.dayNumber(on: now.date) else {
            return now.date < run.input.start ? .startsOn(wake: run.input.wake) : .finished
        }
        let resolved = ScheduleEngine.resolve(run.input, now: now)
        guard let day = resolved.day(number) else { return .finished }
        // A test day with no sets yet. If the Day 8 re-test is skipped, sets start at noon and show instead.
        if day.isTest && day.testReps == nil && day.sets.isEmpty {
            return .testToday(day: number, wake: run.input.wake)
        }
        if number == 15 { return .finished }
        if let next = day.sets.first(where: { $0.status == .upcoming }), let alert = next.alert {
            return .next(day: number, at: alert, reps: next.reps)
        }
        return .dayDone(day: number, done: day.doneCount, total: day.sets.count, reps: day.loggedReps)
    }
}

extension ScheduleEngine {
    /// The Busy hour running now, if any: when alerts come back and how many sets it marked missed (roadmap item 3).
    public static func activeBusy(_ input: RunInput, now: CivilDateTime) -> (until: CivilDateTime, skipped: Int)? {
        guard let start = input.events.compactMap({ event -> CivilDateTime? in
            if case .busy(let at) = event { return at }
            return nil
        }).max() else { return nil }
        let end = start.adding(minutes: 60)
        guard end > now else { return nil }
        var withoutBusy = input
        withoutBusy.events.removeAll { if case .busy(let at) = $0 { return at == start } else { return false } }
        let before = resolve(withoutBusy, now: start)
        let skipped = before.days.flatMap(\.sets).filter { set in
            guard set.status == .upcoming, let alert = set.alert else { return false }
            return alert >= start && alert < end
        }.count
        return (end, skipped)
    }
}
