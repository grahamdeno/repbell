import RepBellEngine

extension Copy {
    static let profileTitle = "Progress"
    static let thisRun = "This run"
    static let yourRecord = "Your record"
    static let scheduleTitle = "Your day"
    static let unlockSection = "Purchase"
    static let startOverTitle = "Start over"
    static let startOverBody = "Ends this run and takes you back to setup. Your record is kept."
    static let startOverConfirmTitle = "Start over?"
    static let startOverConfirmBody = "This run ends and setup starts again. Your record is kept."
    static let recordEmpty = "Finished runs show here."
    static let scheduleNote = "To change these, start over."
    static let unlocked = "Unlocked"
    static let notUnlocked = "Not unlocked"
    static let restorePurchase = "Restore purchase"
    static let restoreNone = "No purchase found for this Apple Account."
    static let undo = "Undo"
    static let didIt = "Done"
    static let dayDone = "Day done"
    static let tapToContinue = "Tap to continue"
    static func celebrationLine(done: Int, total: Int, repsToday: Int) -> String {
        "Set \(done) of \(total) · \(grouped(repsToday)) push-ups today"
    }
    static func dayDoneLine(day: Int, repsToday: Int) -> String {
        "Day \(day): \(grouped(repsToday)) push-ups. Every set done."
    }
    static let profileLabel = "Progress"
    static let alertsSection = "Alerts"
    static let programSection = "Program"
    static let pauseBody = "Stops alerts and holds your place. Resume from Today when you're ready."
    static let settingsTitle = "Settings"
    static let lastRun = "Last run"
    static let observations = "Patterns"
    static let aheadTitle = "What's ahead"

    static func gainLine(_ gain: Int, throughDay: Int) -> String {
        gain >= 0 ? "Up \(gain)% from Day 1 to Day \(throughDay)" : "Down \(-gain)% from Day 1 to Day \(throughDay)"
    }
    static let allTime = "All time"
    static let yourMax = "Your max"
    static let testOnDayOne = "Test on Day 1 to set it."
    static let insightsEmpty = "Your numbers show up here once you start a run."
    static let changeSchedule = "Change your times"
    static let wakeLabel = "Wake"
    static let bedtimeLabel = "Bedtime"
    static let pushUpsToHealth = "Save push-ups to Apple Health"
    static let pushUpsToHealthDetail = "Each finished day is saved as one strength workout, from now on. Rep Bell never reads Health data."
    static let alertsOn = "On"
    static let alertsNeedAttention = "Needs attention"
    static let saveTimes = "Save times"
    static let timesSaved = "Saved. Your sets are re-spaced from now."
    static let scheduleChangeNote = "Changes take effect from now. Sets you've done stay as they are."

    static func windowPreview(before: Int, after: Int, last: ClockTime?) -> String {
        let diff = after - before
        let change: String
        if diff == 0 { change = "Same number of sets left today" }
        else if diff > 0 { change = diff == 1 ? "1 more set today" : "\(diff) more sets today" }
        else { change = -diff == 1 ? "1 fewer set today" : "\(-diff) fewer sets today" }
        if let last { return "From now: \(change), last set at \(Copy.clock(last))." }
        return "From now: \(change)."
    }
    static let alertsCheckTitle = "Alerts check"
    static let alertsCheckBody = "What iOS allows for Rep Bell's alerts and the test-day alarm right now."
    static let testAlertHint = "Tap below, then lock your phone or switch apps. A sample alert arrives in 10 seconds."
    static let sendTestAlert = "Send a test alert"
    static let testAlertSent = "Sent. It arrives in 10 seconds."
    static let testAlertFailed = "iOS refused the alert. Check that notifications are on for Rep Bell."
    static let testAlertTitle = "Test alert. This is what a set looks like."
    static let testAlertBody = "If you can see this, set alerts reach you."
    static let alertsFixHint = "Something above is Off. Open Settings, tap Rep Bell, then Notifications, and turn on Allow Notifications, Banners, Sounds and Time Sensitive."
    static let openSettings = "Open Settings"





    static func doneSet(_ reps: Int) -> String {
        "I did \(reps)"
    }

}
