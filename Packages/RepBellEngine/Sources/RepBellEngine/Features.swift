/// What this build includes, in one place. `ScopeTests` checks each value.
///
/// These are compile-time build settings. Nothing here reads a receipt, a server or the App Store:
/// a feature is never switched by receipt type (sandbox, TestFlight or production).
public enum Features {
    /// Workouts is part of 1.0 (decision of 20 Nov 2026).
    public static let workouts = true

    /// Workouts and Coach voice need the one-time unlock; the 14-day program never does
    /// (decision of 24 Nov 2026, roadmap item 18).
    public static let payment = true

    /// Coach clips are in TestFlight builds for testing while requirement R-1 is open (decision of 23 Nov 2026).
    /// Before any ship go, R-1 is met or this goes back to false and the clips leave the build.
    /// `scripts/privacy_guard.py` reads this value: video files fail CI whenever it is false.
    public static let coachMedia = true
}
