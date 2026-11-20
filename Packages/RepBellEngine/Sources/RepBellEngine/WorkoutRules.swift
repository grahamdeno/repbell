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
