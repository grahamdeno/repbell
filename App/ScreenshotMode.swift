#if DEBUG
import Foundation
import RepBellEngine

/// Debug builds only. `-RBScreenshot <state>` opens the app in one state for the screenshot workflow.
/// Nothing here is compiled into TestFlight or App Store builds.
extension ProgramController {
    static var screenshotState: String? { ScreenshotSeeds.requestedState() }

    /// Loads the seeded run (in memory only; nothing is saved) and opens the screen for the state.
    func applyScreenshot(_ state: String) {
        if let seed = ScreenshotSeeds.library(for: state) {
            library = seed.library
        } else {
            library = LibraryFile()
        }
        let now = CivilDateTime.local(Date())
        switch state {
        case "onboarding-promise": screen = .promise
        case "onboarding-wake": screen = .wake
        case "onboarding-bed": screen = .bed
        case "onboarding-start": screen = .startDay
        case "onboarding-alerts": screen = .alerts
        case "onboarding-alerts-denied": alertsDenied = true; screen = .alerts
        case "onboarding-ready": screen = .ready
        case "day-start": screen = .dayStart
        case "counter-zero": draftCount = 0; screen = .counter(1)
        case "counter-mid": draftCount = 23; screen = .counter(1)
        case "counter-day8-high": draftCount = 64; screen = .counter(8)
        case "confirm": screen = .confirm(day: 1, reps: 40)
        case "celebration-set":
            screen = .today
            celebration = Celebration(day: 3, reps: 24, done: 4, total: 16, repsToday: 96, dayComplete: false)
        case "celebration-day":
            screen = .today
            celebration = Celebration(day: 3, reps: 24, done: 16, total: 16, repsToday: 384, dayComplete: true)
        case "celebration-final":
            screen = .result
            celebration = Celebration(day: 15, reps: 58, done: 0, total: 0, repsToday: 4312, dayComplete: true,
                                      finalTest: true, startMax: 40, percent: 45)
        case "desk-stretch":
            screen = .today
            deskStretch = DeskStretch.all[0]
        case "result-final", "result-ended": screen = .result
        case "rerun": screen = .rerun
        case "hurts": screen = .hurts
        case "paywall": screen = .paywall
        case "player": screen = .studioPlayer("core")
        case "progress": screen = .today; path = [.progress]
        case "settings": screen = .today; path = [.settings]
        case "alerts-check": screen = .today; path = [.settings, .alertsCheck]
        case "about": screen = .today; path = [.settings, .about]
        case "workouts": screen = .today; path = [.workouts]
        case "workout-settings": screen = .today; path = [.workouts, .workoutSettings]
        case "workout-session": screen = .today; path = [.workouts, .workoutSession("core")]
        case "fit-my-time": screen = .today; path = [.workouts, .fitMyTime]
        case "fit-session":
            screen = .today
            path = [.workouts, .fitMyTime]
            fitMyTime(minutes: 15)
        default: screen = library.current == nil ? .promise : .today
        }
        _ = now
    }
}
#endif
