import Foundation

/// The copy deck. Brackets in the plan are filled from the engine. No exclamation marks.
public enum Copy {
    public static let promiseHeadlineLead = "14"
    public static let promiseHeadline = "Days.\nYour max\ngoes up."
    public static let promiseBody = "Tell it your max once. For two weeks, your phone and watch tell you when to drop and how many. One tap logs each set."
    public static let healthNote = "Shoulder, wrist or heart concerns? Check with a doctor first."

    public static let wakeHeadline = "When do you\nwake up?"
    public static let wakeBody = "Your first set lands here. Test days start with an alarm at this time."

    public static let bedHeadline = "When do you\ngo to bed?"
    public static let bedBody = "Your last set is an hour before."

    public static let startHeadline = "When do\nyou start?"
    public static let startBody = "Day 1 opens with your max test."
    public static let tomorrowMorning = "Tomorrow morning"
    public static let today = "Today"

    public static let alertsHeadline = "Every set\nis an alert."
    public static let alertsBody = "No alerts, no program. Apple will ask twice."
    public static let setAlertsTitle = "Set alerts"
    public static let setAlertsDetail = "Sets are due at a set time, so they come through Focus. Done and In 10 min right on the alert."
    public static let testAlarmTitle = "Test-day alarm"
    public static let testAlarmDetail = "Days 1, 8 and 15 start with an alarm that rings even on silent."
    public static let allowAlerts = "Allow alerts"
    public static let timeSensitiveSettings = "Sets are due at a set time, so they come through Focus. You can change this in Settings."

    public static let withYourTest = "with your test."
    public static let nothingElse = "Nothing else to set. Sleep well."

    public static let testAlarm = "Test day. As many as you can, good form."
    public static let counterPrompt = "How many did you do? Slide your thumb up or down to set the number."
    public static let goodForm = "Good form, to failure"

    public static let startTheDay = "Start the day"
    public static let recount = "Recount"

    public static let done = "Done"
    public static let inTen = "In 10 min"
    public static let busy = "Busy for 1 hour"
    public static let somethingHurts = "Something hurts?"
    public static let back = "Back"
    public static let share = "Share"
    public static let runAgain = "Run it again"
    public static let next = "Next"
    public static let start = "Start"

    public static let hurtsHeadline = "Something\nhurts?"
    public static let hurtsBody = "Sharp or joint pain is a reason to stop. Your progress is kept either way."
    public static let pauseTitle = "Pause the program"
    public static let endTitle = "End it here"
    public static let endDetail = "Your days so far are saved. Start a new run any time."

    public static let dayEightFallback = "No re-test today, so week 2 uses your Day 1 max. Sets start now."

    public static let aboutTitle = "About"
    public static let aboutBody = "Rep Bell runs the 14-day program popularized as Hit the Deck by The Modern Rogue. The same schedule belongs to a longer tradition, sometimes called the Evil Russian program. Rep Bell is not endorsed by The Modern Rogue or anyone else."

    public static let unlockTitle = "Unlock the full program"
    public static let unlockBody = "The first three days are free. One time, $4.99, for the rest of this run and every rerun."
    public static let unlockButton = "Unlock"
    public static let unlockMissing = "The unlock is not available yet."

    public static let paused = "Paused"
    public static let resume = "Resume"
    public static let startTest = "Start the test"
    public static let todaysSets = "Today's sets"
    public static let wordmark = "Rep Bell"

    public static func pauseDetail(day: Int) -> String {
        "No alerts until you resume. Day \(day) picks up where you left off."
    }

    public static func lastSet(at time: ClockTime) -> String {
        "Last set at \(clock(time))"
    }

    public static func setupReady(when: String) -> String {
        "Day 1 starts \(when)"
    }

    public static func testEyebrow(day: Int) -> String {
        "Test · Day \(day)"
    }

    public static func yourMaxLine(_ max: Int) -> String {
        "Your max"
    }

    public static func todayPlan(reps: Int, intervalMinutes: Int) -> String {
        "Today: \(reps), every \(intervalPhrase(intervalMinutes))"
    }

    public static func confirmDetail(first: CivilDateTime, last: CivilDateTime, count: Int) -> String {
        "First set at \(clock(first)) Last set at \(clock(last)) That's \(count) sets."
    }

    public static func noSetsLeft(reps: Int, intervalMinutes: Int) -> String {
        "Today: \(reps), every \(intervalPhrase(intervalMinutes)). No sets left in today's window."
    }

    public static func setAlertTitle(reps: Int) -> String { "\(reps) now" }

    public static func setAlertBody(index: Int, total: Int, day: Int) -> String {
        "Set \(index) of \(total) · Day \(day)"
    }

    public static func nextSetTime(_ time: CivilDateTime) -> String {
        "Next set at \(clock(time))"
    }

    public static func pushUpsIn(minutes: Int) -> String {
        "push-ups in \(minutes) min"
    }

    public static func tally(done: Int, total: Int, missed: Int) -> String {
        "\(done) of \(total) done, \(missed) missed"
    }

    public static func repsSoFar(_ reps: Int) -> String {
        "\(grouped(reps)) push-ups so far today"
    }

    public static func busyConfirm(until: CivilDateTime) -> String {
        "Alerts off until \(clock(until)) Sets in this hour count as missed."
    }

    public static func hardDay(sets: Int, reps: Int) -> String {
        "Tomorrow is the hard day: \(sets) sets of \(reps). Sleep well."
    }

    public static func testEve(wake: ClockTime) -> String {
        "Test tomorrow at \(clock(wake))."
    }

    public static func endOfDay(done: Int, total: Int, reps: Int, missed: Int) -> String {
        if missed > 0 {
            return "\(done) of \(total). \(grouped(reps)) push-ups today. Tomorrow starts fresh."
        }
        return "\(done) of \(total). \(grouped(reps)) push-ups today."
    }

    public static func resultLine(dayOne: Int, dayFifteen: Int, reps: Int, percent: Int) -> String {
        "Day 1 \(dayOne) → Day 15 \(dayFifteen) · \(grouped(reps)) push-ups in 14 days · \(signedPercent(percent)) on your max"
    }

    public static func dayProgress(_ day: Int) -> String {
        "Day \(day) of 14"
    }

    public static func maxLabel(_ max: Int) -> String {
        "Max \(max)"
    }

    public static func watchTally(done: Int, total: Int, reps: Int) -> String {
        "\(done) of \(total) · \(grouped(reps)) today"
    }

    public static func widgetNext(_ time: CivilDateTime) -> String {
        "Next set \(shortClock(time))"
    }

    public static func widgetReps(reps: Int, day: Int) -> String {
        "\(reps) · Day \(day)"
    }

    public static func intervalPhrase(_ minutes: Int) -> String {
        switch minutes {
        case 60: return "hour"
        case 120: return "2 hours"
        default: return "\(minutes) min"
        }
    }

    public static func clock(_ time: ClockTime) -> String {
        clock(minutes: time.minutesFromMidnight)
    }

    public static func clock(_ time: CivilDateTime) -> String {
        clock(minutes: time.minutes)
    }

    public static func shortClock(_ time: CivilDateTime) -> String {
        clock(minutes: time.minutes)
    }

    public static func hourMinute(_ time: ClockTime) -> String {
        String(format: "%d:%02d", displayHour(time.hour), time.minute)
    }

    public static func grouped(_ value: Int) -> String {
        let sign = value < 0 ? "-" : ""
        let digits = Array(String(abs(value)))
        var pieces: [String] = []
        var index = digits.count
        while index > 0 {
            let start = max(0, index - 3)
            pieces.append(String(digits[start..<index]))
            index = start
        }
        return sign + pieces.reversed().joined(separator: ",")
    }

    public static func signedPercent(_ percent: Int) -> String {
        if percent > 0 { return "+\(percent)%" }
        return "\(percent)%"
    }

    public static func percentGain(from start: Int, to end: Int) -> Int {
        guard start > 0 else { return 0 }
        return ((end - start) * 100) / start
    }

    public static func minutesUntil(_ alert: CivilDateTime, from now: CivilDateTime) -> Int {
        max(0, now.minutes(until: alert))
    }

    private static func clock(minutes: Int) -> String {
        let normalized = ((minutes % 1440) + 1440) % 1440
        let hour24 = normalized / 60
        let minute = normalized % 60
        let period = hour24 < 12 ? "a.m." : "p.m."
        return String(format: "%d:%02d %@", displayHour(hour24), minute, period)
    }

    private static func displayHour(_ hour24: Int) -> Int {
        let wrapped = hour24 % 12
        return wrapped == 0 ? 12 : wrapped
    }
}
