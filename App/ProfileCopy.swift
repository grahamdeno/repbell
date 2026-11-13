import RepBellEngine

extension Copy {
    static let profileTitle = "Profile"
    static let thisRun = "This run"
    static let yourRecord = "Your record"
    static let scheduleTitle = "Schedule"
    static let unlockSection = "Unlock"
    static let startOverTitle = "Start over"
    static let startOverBody = "Ends this run and takes you back to setup. Your record and your unlock are kept."
    static let startOverConfirmTitle = "Start over?"
    static let startOverConfirmBody = "This run ends and setup starts again. Your record and your unlock are kept."
    static let recordEmpty = "Finished runs show here."
    static let scheduleNote = "To change these, start over."
    static let unlocked = "Unlocked"
    static let notUnlocked = "Days 1 to 3 of your first run are free"
    static let restorePurchase = "Restore purchase"
    static let restoreNone = "No purchase found for this Apple Account."
    static let busyCaption = "Pauses alerts for an hour. Sets in that hour count as missed."
    static let busySheetTitle = "Pause alerts for an hour?"
    static let busyPause = "Pause for 1 hour"
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
    static let profileLabel = "Profile"

    static func busyNothingSkipped(resume: String) -> String {
        "No sets fall in the next hour, so nothing is skipped. Alerts resume at \(resume)."
    }

    static func busySkipIntro(count: Int) -> String {
        count == 1 ? "This set will count as missed:" : "These \(count) sets will count as missed:"
    }

    static func busyResume(_ resume: String) -> String {
        "Alerts resume at \(resume). Your max and the rest of the program don't change, and you can undo this."
    }

    static func busyActive(_ until: String) -> String {
        "Alerts paused until \(until)"
    }

    static func doneSet(_ reps: Int) -> String {
        "I did \(reps)"
    }

    static func skippedRow(time: String, reps: Int) -> String {
        "\(time) · \(reps) push-ups"
    }
}
