/// Rules for the max-test flow that the app screens follow. Kept here so they are unit tested.
public enum TestFlow {
    /// The test day whose counter should open by itself when the app comes to the front, or nil.
    ///
    /// The counter opens only on a test day, within 90 minutes after wake time, before the test is logged,
    /// and not when the person already chose "Not yet" for that date.
    public static func counterToOpen(run: PersistedRun?, now: CivilDateTime, deferredOn: CivilDate?) -> Int? {
        guard let run, !run.ended, run.pausedAt == nil else { return nil }
        guard let number = run.input.dayNumber(on: now.date) else { return nil }
        guard DayTemplate.day(number).isTest else { return nil }
        if deferredOn == now.date { return nil }
        let resolved = ScheduleEngine.resolve(run.input, now: now)
        guard resolved.day(number)?.testReps == nil else { return nil }
        let delta = now.minutes - run.input.wake.minutesFromMidnight
        guard delta >= 0 && delta <= 90 else { return nil }
        return number
    }

    /// Whether the counter's Done can act. At 0 it is disabled.
    public static func canSubmit(count: Int) -> Bool { count >= 1 }
}

extension RunInput {
    /// Corrects the number logged for a test day. The test keeps its original time, so nothing else in the
    /// schedule moves. Returns false when that day has no logged test.
    @discardableResult
    public mutating func correctTest(day: Int, reps: Int) -> Bool {
        guard reps >= 1 else { return false }
        var found = false
        events = events.map { event in
            if case .test(let d, _, let at) = event, d == day {
                found = true
                return .test(day: d, reps: reps, at: at)
            }
            return event
        }
        if found && day == 1 { dayOneMax = reps }
        return found
    }
}
