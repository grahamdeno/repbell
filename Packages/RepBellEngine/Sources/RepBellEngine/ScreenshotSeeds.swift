#if DEBUG
import Foundation

/// Debug builds only: run states for screenshots, built relative to "now" so the real schedule engine produces them.
/// Never compiled into TestFlight or App Store builds (Release configuration).
public enum ScreenshotSeeds {
    /// The launch argument: `-RBScreenshot <state>`.
    public static let argument = "-RBScreenshot"

    public static func requestedState(_ arguments: [String] = ProcessInfo.processInfo.arguments) -> String? {
        guard let i = arguments.firstIndex(of: argument), i + 1 < arguments.count else { return nil }
        return arguments[i + 1]
    }

    /// A clock time `minutes` from now (negative is earlier), wrapped to a day.
    static func clock(_ now: CivilDateTime, plus minutes: Int) -> ClockTime {
        let m = ((now.minutes + minutes) % 1440 + 1440) % 1440
        return ClockTime(hour: m / 60, minute: m % 60)
    }

    /// A run on program day `day` today, with the given wake offset from now.
    /// The screenshot workflow sets the time zone so "now" is mid-afternoon, so these offsets stay on one date.
    static func run(day: Int, now: CivilDateTime, wakeOffset: Int, bedOffset: Int? = nil, max: Int = 40) -> RunInput {
        let wake = clock(now, plus: wakeOffset)
        let bed = clock(now, plus: bedOffset ?? (wakeOffset + 16 * 60))
        return RunInput(dayOneMax: max, wake: wake, bed: bed, start: now.date.addingDays(-(day - 1)))
    }

    /// Logs the tests that would have happened before `day`.
    static func withTests(_ input: RunInput, upTo day: Int, day8: Int = 46) -> RunInput {
        var out = input
        let d1 = input.date(forDay: 1)
        out.events.append(.test(day: 1, reps: input.dayOneMax, at: CivilDateTime(date: d1, minutes: input.wake.minutesFromMidnight + 5)))
        if day > 8 {
            out.events.append(.test(day: 8, reps: day8, at: CivilDateTime(date: input.date(forDay: 8), minutes: input.wake.minutesFromMidnight + 5)))
        }
        return out
    }

    /// Marks sets done on earlier days: every set, except every `skipEvery`th one, which is left missed.
    static func fillPastDays(_ input: RunInput, through lastDay: Int, now: CivilDateTime, skipEvery: Int = 6) -> RunInput {
        var out = input
        guard lastDay >= 2 else { return out }
        for day in 2...lastDay {
            let resolved = ScheduleEngine.resolve(out, now: now)
            guard let scheduled = resolved.day(day) else { continue }
            for (n, set) in scheduled.sets.enumerated() where (n + 1) % skipEvery != 0 {
                out.events.append(.done(day: day, index: set.index, at: set.grid.adding(minutes: 2)))
            }
        }
        return out
    }

    /// Marks today's sets done, in order, while their time is before `until`; `skip` indexes stay missed.
    static func doneToday(_ input: RunInput, day: Int, now: CivilDateTime, until: CivilDateTime, skip: Set<Int> = []) -> RunInput {
        var out = input
        guard let today = ScheduleEngine.resolve(out, now: now).day(day) else { return out }
        for set in today.sets where set.grid <= until && !skip.contains(set.index) {
            out.events.append(.done(day: day, index: set.index, at: set.grid.adding(minutes: 1)))
        }
        return out
    }

    public struct Seed {
        public var library: LibraryFile
        public var note: String
    }

    /// The library for a named state, or nil when the state needs no run (onboarding) or isn't known.
    public static func library(for state: String, now date: Date = Date()) -> Seed? {
        let now = CivilDateTime.local(date)
        func file(_ input: RunInput, pausedAt: CivilDateTime? = nil, ended: Bool = false, history: [PersistedRun] = []) -> LibraryFile {
            LibraryFile(runsStarted: 1, unlocked: false, current: PersistedRun(input: input, pausedAt: pausedAt, ended: ended), history: history)
        }
        switch state {
        case "today-day1-before-test":
            let input = RunInput(dayOneMax: 0, wake: clock(now, plus: 120), bed: clock(now, plus: 120 + 16 * 60), start: now.date)
            return Seed(library: file(input), note: "Run starts today; wake time 2 hours from now; no test logged")
        case "today-set-due", "celebration-set", "celebration-day", "desk-stretch":
            // Day 3 sets every 45 min. Wake 138 min ago: sets at -138, -93, -48, -3 (due now).
            var input = withTests(run(day: 3, now: now, wakeOffset: -138), upTo: 3)
            input = fillPastDays(input, through: 2, now: now)
            input = doneToday(input, day: 3, now: now, until: now.adding(minutes: -40))
            return Seed(library: file(input), note: "Day 3, wake 138 min ago, three sets done, the fourth due 3 min ago")
        case "today-between-sets":
            var input = withTests(run(day: 3, now: now, wakeOffset: -155), upTo: 3)
            input = fillPastDays(input, through: 2, now: now)
            input = doneToday(input, day: 3, now: now, until: now)
            return Seed(library: file(input), note: "Day 3, four sets done, next set in 25 min")
        case "today-missed":
            // Day 5 sets every 30 min. Wake 205 min ago.
            var input = withTests(run(day: 5, now: now, wakeOffset: -205), upTo: 5)
            input = fillPastDays(input, through: 4, now: now)
            input = doneToday(input, day: 5, now: now, until: now, skip: [2, 3, 5])
            return Seed(library: file(input), note: "Day 5, three of seven sets so far missed")
        case "today-busy":
            var input = withTests(run(day: 3, now: now, wakeOffset: -150), upTo: 3)
            input = fillPastDays(input, through: 2, now: now)
            input = doneToday(input, day: 3, now: now, until: now.adding(minutes: -10))
            input.events.append(.busy(at: now.adding(minutes: -5)))
            return Seed(library: file(input), note: "Day 3, Busy for 1 hour tapped 5 min ago")
        case "today-finished":
            // Day 4 window over: woke 10 h ago, bedtime now, so the last set was an hour ago.
            var input = withTests(run(day: 4, now: now, wakeOffset: -600, bedOffset: 0), upTo: 4)
            input = fillPastDays(input, through: 3, now: now)
            input = doneToday(input, day: 4, now: now, until: now)
            return Seed(library: file(input), note: "Day 4, every set done, window closed")
        case "today-paused":
            var input = withTests(run(day: 6, now: now, wakeOffset: -180), upTo: 6)
            input = fillPastDays(input, through: 5, now: now)
            return Seed(library: file(input, pausedAt: now.adding(minutes: -60)), note: "Day 6, paused an hour ago")
        case "today-day8-test", "counter-day8-high":
            var input = withTests(run(day: 8, now: now, wakeOffset: -30), upTo: 8)
            input = fillPastDays(input, through: 7, now: now)
            return Seed(library: file(input), note: "Day 8, woke 30 min ago, re-test not logged (after noon the fallback applies)")
        case "today-day15":
            var input = withTests(run(day: 15, now: now, wakeOffset: -30), upTo: 15)
            input = fillPastDays(input, through: 14, now: now)
            return Seed(library: file(input), note: "Day 15, final test not logged")
        case "result-final", "rerun", "celebration-final":
            var input = withTests(run(day: 15, now: now, wakeOffset: -60), upTo: 15)
            input = fillPastDays(input, through: 14, now: now)
            input.events.append(.test(day: 15, reps: 58, at: now.adding(minutes: -20)))
            return Seed(library: file(input), note: "Day 15 final test logged: 40 to 58")
        case "result-ended":
            var input = withTests(run(day: 6, now: now, wakeOffset: -240), upTo: 6)
            input = fillPastDays(input, through: 5, now: now)
            input = doneToday(input, day: 6, now: now, until: now)
            let ended = PersistedRun(input: input, ended: true)
            return Seed(library: LibraryFile(runsStarted: 1, current: ended, history: [ended]), note: "Run ended on Day 6 through Something hurts")
        case "progress", "settings", "alerts-check", "about", "workouts", "workout-settings", "workout-session",
             "fit-my-time", "fit-session", "player", "hurts", "paywall", "day-start", "counter-zero", "counter-mid", "confirm":
            let day = (state == "counter-zero" || state == "counter-mid" || state == "confirm") ? 1 : 9
            if day == 1 {
                let input = RunInput(dayOneMax: 0, wake: clock(now, plus: -10), bed: clock(now, plus: 15 * 60), start: now.date)
                return Seed(library: file(input), note: "Day 1, woke 10 min ago, test not logged")
            }
            var input = withTests(run(day: 9, now: now, wakeOffset: -200), upTo: 9)
            input = fillPastDays(input, through: 8, now: now)
            input = doneToday(input, day: 9, now: now, until: now.adding(minutes: -15), skip: [3])
            input.events.append(.snooze(day: 9, index: 2, at: now.adding(minutes: -170)))
            return Seed(library: file(input), note: "Day 9 of a run with real-looking logs (a few sets missed, one snooze)")
        default:
            return nil
        }
    }
}
#endif
