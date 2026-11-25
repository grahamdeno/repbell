import Foundation

/// Coach voice (roadmap item 17): one short line after a set or a finished day, from the person's own numbers.
public enum CoachMode: String, CaseIterable, Codable, Sendable {
    case off, coaching, push

    /// The voice in use: the stored choice while Workouts and Coach voice are unlocked, otherwise Off (item 18).
    public static func effective(stored: CoachMode, paidFeaturesOpen: Bool) -> CoachMode {
        paidFeaturesOpen ? stored : .off
    }
}

/// The numbers a coach line may use. Numbers only: nothing a person typed ever reaches the model.
public struct CoachFacts: Equatable, Sendable, Codable {
    public enum Moment: String, Sendable, Codable { case afterSet, dayDone }

    public var moment: Moment
    public var day: Int
    public var setsDone: Int
    public var setsTotal: Int
    public var setsMissed: Int
    public var repsThisSet: Int
    public var repsToday: Int
    public var repsPlannedToday: Int
    public var snoozesToday: Int
    /// The most push-ups logged on any earlier day of this run; 0 when there is none.
    public var bestEarlierDay: Int
    /// Earlier days of this run with every set done.
    public var fullDaysBefore: Int
    public var dayOneMax: Int

    public init(moment: Moment, day: Int, setsDone: Int, setsTotal: Int, setsMissed: Int, repsThisSet: Int,
                repsToday: Int, repsPlannedToday: Int, snoozesToday: Int, bestEarlierDay: Int,
                fullDaysBefore: Int, dayOneMax: Int) {
        self.moment = moment
        self.day = day
        self.setsDone = setsDone
        self.setsTotal = setsTotal
        self.setsMissed = setsMissed
        self.repsThisSet = repsThisSet
        self.repsToday = repsToday
        self.repsPlannedToday = repsPlannedToday
        self.snoozesToday = snoozesToday
        self.bestEarlierDay = bestEarlierDay
        self.fullDaysBefore = fullDaysBefore
        self.dayOneMax = dayOneMax
    }

    public var setsLeft: Int { max(setsTotal - setsDone - setsMissed, 0) }
    public var daysToGo: Int { max(15 - day, 0) }
    /// Day 8 is the re-test and Day 15 the final test, so the day after Day 7 or Day 14 has no sets.
    public var testTomorrow: Bool { day == 7 || day == 14 }

    /// Builds the facts for a day from the resolved run. Earlier days give the best day and full days.
    public static func make(run: ResolvedRun, day: Int, repsThisSet: Int, dayOneMax: Int, moment: Moment) -> CoachFacts? {
        guard let today = run.day(day) else { return nil }
        let earlier = run.days.filter { $0.number < day && !$0.sets.isEmpty }
        return CoachFacts(
            moment: moment,
            day: day,
            setsDone: today.doneCount,
            setsTotal: today.sets.count,
            setsMissed: today.missedCount,
            repsThisSet: repsThisSet,
            repsToday: today.loggedReps,
            repsPlannedToday: today.sets.reduce(0) { $0 + $1.reps },
            snoozesToday: today.sets.reduce(0) { $0 + $1.snoozes },
            bestEarlierDay: earlier.map(\.loggedReps).max() ?? 0,
            fullDaysBefore: earlier.filter { $0.doneCount == $0.sets.count }.count,
            dayOneMax: dayOneMax
        )
    }

    /// Every number a line is allowed to contain.
    var allowedNumbers: Set<Int> {
        [day, setsDone, setsTotal, setsMissed, repsThisSet, repsToday, repsPlannedToday, snoozesToday,
         bestEarlierDay, fullDaysBefore, dayOneMax, setsLeft, daysToGo, 14, 15]
    }
}

public enum CoachVoice {
    /// Item 19: how long the Watch waits for the iPhone's model line after a set. A reply that comes later is
    /// dropped, so the text never changes while the person is reading. The iPhone itself gives the model 1.2 s.
    public static let watchReplyWindow: Double = 2.5

    /// The Watch's request to the iPhone: the facts as JSON (numbers only) and the voice the Watch wrote its line in.
    public static func watchRequest(_ facts: CoachFacts, mode: CoachMode) -> [String: Any] {
        guard let data = try? JSONEncoder().encode(facts) else { return [:] }
        return ["kind": "coach", "facts": data, "mode": mode.rawValue]
    }

    /// The facts and voice in a Watch request, or nil if the message isn't one.
    public static func parseWatchRequest(_ message: [String: Any]) -> (facts: CoachFacts, mode: CoachMode)? {
        guard message["kind"] as? String == "coach", let data = message["facts"] as? Data,
              let mode = CoachMode(rawValue: message["mode"] as? String ?? ""),
              let facts = try? JSONDecoder().decode(CoachFacts.self, from: data) else { return nil }
        return (facts, mode)
    }

    /// What the iPhone does with a Watch request.
    public enum WatchAnswer: Equatable, Sendable {
        /// Write a model line: the iPhone's voice matches the Watch's.
        case write
        /// The voice is off on the iPhone (turned off, or the unlock refunded): the Watch takes its line down.
        case clear
        /// The voices differ: the Watch keeps its written line, so the text never changes voice.
        case keep
    }

    public static func watchAnswer(phoneMode: CoachMode, watchMode: CoachMode) -> WatchAnswer {
        if phoneMode == .off { return .clear }
        return phoneMode == watchMode ? .write : .keep
    }

    /// A model line counts only if it arrives inside the window.
    public static func watchReplyInTime(elapsed: Double) -> Bool {
        elapsed >= 0 && elapsed <= watchReplyWindow
    }

    /// Item 19: a set that becomes due after the line went up takes the screen back, so a line never hides a set.
    public static func watchShowsLine(shownAt: CivilDateTime, dueAlert: CivilDateTime?) -> Bool {
        guard let dueAlert else { return true }
        return dueAlert <= shownAt
    }

    /// Whether logging this set on the Watch brings a line: only a set that was still to do, like the iPhone.
    /// The Watch decides from its own copy of the day; if the iPhone logged the set and that copy is behind, the
    /// Watch can show one line the iPhone wouldn't, which is harmless.
    public static func watchGetsLine(mode: CoachMode, statusBefore: SetStatus?) -> Bool {
        mode != .off && statusBefore == .upcoming
    }

    // MARK: Rules every line must pass, written or generated

    /// Matched as the start of a word ("dammit", "shitty"); "ass" and "hell" only as whole words.
    static let profanityStems = ["fuck", "shit", "damn", "dammit", "bitch", "crap", "piss", "bastard", "asshole"]
    static let profanityWords: Set<String> = ["ass", "hell"]
    /// Push limits: nothing about the body, looks or worth, nothing that urges past pain or injury, no military words.
    /// Matched as the start of a word, so "nobody" and "toward" pass.
    static let neverSaidStems = ["fat", "weight", "body", "belly", "ugly", "looks", "worthless", "pathetic", "loser",
                                 "useless", "stupid", "pain", "injur", "hurt", "bleed", "puke", "soldier", "drill",
                                 "mission", "battle", "war", "fight", "combat", "troop", "march", "enemy"]
    /// Coaching carries no guilt. Matched as the start of a word ("missing", "snoozed", "skipped").
    static let guiltStems = ["miss", "snooz", "skip", "fail", "excuse", "quit", "soft", "lazy", "promise", "owe",
                             "gone", "table", "nobody", "behind", "broke"]
    static let guiltPhrases = ["should have", "pushed back", "got away"]
    /// Numbers must be digits so the made-up-number check can see them.
    /// "one" is left out: "the next one" is ordinary wording.
    static let numberWords: Set<String> = ["two", "three", "four", "five", "six", "seven", "eight", "nine",
                                           "ten", "eleven", "twelve", "thirteen", "fourteen", "fifteen", "sixteen",
                                           "seventeen", "eighteen", "nineteen", "twenty", "thirty", "forty", "fifty",
                                           "sixty", "seventy", "eighty", "ninety", "hundred", "thousand", "dozen"]

    /// Whether a line may be shown for this mode and these facts.
    public static func accepts(_ line: String, mode: CoachMode, facts: CoachFacts) -> Bool {
        let text = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, text.count <= 200, !text.contains("!"), !text.contains("\n") else { return false }
        let lower = text.lowercased()
        let words = lower.split { !$0.isLetter }.map(String.init)
        func starts(_ stems: [String]) -> Bool {
            words.contains { word in stems.contains { word.hasPrefix($0) } }
        }
        if words.contains(where: { profanityWords.contains($0) }) || starts(profanityStems) { return false }
        if starts(neverSaidStems) { return false }
        if words.contains(where: { numberWords.contains($0) }) { return false }
        if mode == .coaching {
            if starts(guiltStems) { return false }
            if guiltPhrases.contains(where: { lower.contains($0) }) { return false }
        }
        // No made-up numbers: every number in the line is one of the person's own.
        let numbers = text.split { !$0.isNumber && $0 != "," }
            .compactMap { Int($0.replacingOccurrences(of: ",", with: "")) }
        return numbers.allSatisfy { facts.allowedNumbers.contains($0) }
    }

    // MARK: Written lines (used when the on-device model is unavailable, slow, or breaks a rule)

    public static func writtenLine(mode: CoachMode, facts: CoachFacts) -> String? {
        let options = writtenOptions(mode: mode, facts: facts)
        guard !options.isEmpty else { return nil }
        let seed = facts.day * 31 + facts.setsDone * 7 + facts.setsMissed
        return options[seed % options.count]
    }

    static func count(_ n: Int, _ one: String, _ many: String) -> String {
        "\(n) \(n == 1 ? one : many)"
    }

    static func writtenOptions(mode: CoachMode, facts f: CoachFacts) -> [String] {
        let setsLeft = count(f.setsLeft, "set", "sets")
        let days = count(f.daysToGo, "day", "days")
        let test = f.day == 7 ? "the re-test" : "the final test"
        switch (mode, f.moment) {
        case (.off, _):
            return []
        case (.coaching, .afterSet):
            if f.setsLeft == 0 { return ["That's the day's work. Rest easy."] }
            var lines = [
                "\(f.repsToday) so far today. \(setsLeft) left, and each one moves you toward Day 15.",
                "Keep the next one just as clean. \(setsLeft) to go.",
            ]
            if f.bestEarlierDay > 0 && f.repsToday > f.bestEarlierDay {
                lines.append("\(f.repsToday) today already beats your best day of \(f.bestEarlierDay).")
            }
            return lines
        case (.coaching, .dayDone):
            if f.testTomorrow {
                return ["Tomorrow is \(test). Today's work is what you bring to it."]
            }
            var lines = [
                "\(days) to Day 15. Each finished day gets you there.",
                "You started at a max of \(f.dayOneMax). Days like this one build past it.",
            ]
            if f.bestEarlierDay > 0 && f.repsToday > f.bestEarlierDay {
                lines.append("\(f.repsToday) is your best day yet, up from \(f.bestEarlierDay).")
            }
            return lines
        case (.push, .afterSet):
            // Missed and snooze lines come every third set, so they don't take over the rest of a long day.
            let callOut = f.setsDone % 3 == 0
            if f.setsMissed > 0 && (callOut || f.setsLeft == 0) {
                let times = f.setsMissed == 1 ? "once" : "\(f.setsMissed) times"
                return ["\(count(f.setsMissed, "set", "sets")) missed today. You made a promise and broke it \(times) today. The only fix is the next one, on time, no story.",
                        "You let \(f.setsMissed) slip today. Nobody else saw it. You did. Fix it with the next one."]
            }
            if f.snoozesToday > 0 && f.setsMissed == 0 && callOut {
                return ["You pushed the bell back \(count(f.snoozesToday, "time", "times")) today. Each one makes the next easier. Next time, let the bell win."]
            }
            if f.setsLeft == 0 && f.setsMissed == 0 {
                return ["\(f.setsDone) of \(f.setsTotal). You kept your word today. Don't celebrate it. That's the price of being who you said you are."]
            }
            return [pushGrit[(f.setsDone + f.day * 5) % pushGrit.count]]
        case (.push, .dayDone):
            if f.setsMissed > 0 {
                return ["\(f.setsDone) of \(f.setsTotal). You let \(f.setsMissed) go today and you know exactly why. Next time there's no why. Every set."]
            }
            if f.testTomorrow {
                return ["Every set done. Tomorrow is \(test). Nobody cares how today felt. Walk in and find out what you built."]
            }
            return [
                "\(f.setsTotal) of \(f.setsTotal). Good. That's the minimum, not the finish. Wake up and do it again.",
                "Every set, on time. Nobody hands out medals for that. It's the job, and the job starts again next time.",
            ] + (f.day >= 4 ? ["Day \(f.day) done. Most people would have quit by now. You didn't. Don't start."] : [])
        }
    }

    /// Push after a set (item 17): blunt, varied, mostly without numbers, so a day of 35 sets doesn't read the
    /// same line twice in a row. Chosen by set, so consecutive sets get consecutive lines.
    static let pushGrit = [
        "That set is already history. The next one is yours to do and nobody else's. Be ready.",
        "The voice saying you've done enough shows up every day. It hasn't been right yet.",
        "Comfortable people don't finish programs like this. Today isn't supposed to feel easy, and it won't.",
        "You didn't come this far to coast. The next set is where you find out who's actually doing this.",
        "You stopped feeling like it sets ago. That's fine. Feelings were never part of the deal.",
        "Every set you do when you don't feel like it is the one that changes you. Go collect another one.",
        "The person you want to be does the next set without negotiating. Be that person.",
        "Tired is a report, not a decision. Note it and be on the floor when the bell rings.",
        "Nobody's impressed by the sets you've done. Only by the ones you finish when it gets hard.",
        "You're not done. You're not close to done. Stop counting and start owning the rest of the day.",
        "Easy days don't build anything. This one isn't easy, which means it's working.",
        "The bell doesn't care how you feel. Neither does the program. Show up anyway.",
        "Most people quit right about here. That's exactly why most people stay where they are.",
        "Your excuses are ready. So is the next set. Only one of those makes you better.",
        "Talk is cheap and so are good intentions. Only the reps get written down.",
        "You want the result without the grind. There's no such deal. Get back to work.",
        "That set is a receipt, not a trophy. Earn the next one.",
        "Some part of you is hoping the bell forgets. It won't. Be ready when it rings.",
        "Doubt is loud right now. Answer it the only way that works: the next set, done clean.",
        "You signed up for every set, not the ones that fit your mood. Keep your word.",
        "The hard sets are the only ones that change anything. You just did one. Do it again.",
        "Don't wait to feel ready. Ready shows up after you start.",
        "Every time you show up when you'd rather not, quitting gets a little quieter. Keep it quiet.",
        "Average is easy and crowded. Do the next set and leave the crowd where it is.",
        "Stop waiting for this to feel good. It won't. Doing it anyway is the whole point.",
        "This is where you separate from who you were last week. Next set.",
        "Weak excuses sound reasonable at this point in the day. Ignore every one of them.",
        "You owe yourself every set you promised this morning. Pay it.",
        "Most people never sign up for something this relentless. You did. Act like it.",
        "When it rings again, don't think. Thinking is where quitting starts. Just go.",
        "You can rest when today is done. Not before.",
        "Repetition is where this stops being a mood and becomes who you are. Next set.",
        "Nobody's grading effort. The floor counts reps, and the day isn't finished.",
        "Your head keeps offering a way out. Turn it down on the next set.",
        "The version of you that skips this set is already making plans. Don't let it win.",
        "Discomfort is the price of the result. You already paid for this one. Pay for the next.",
    ]

    // MARK: Prompt for the on-device model

    public static func instructions(mode: CoachMode) -> String {
        let common = """
        You write one line for a push-up app, shown right after the person logs a set or finishes a day. \
        Use only the numbers given and never invent a number. Short sentences, under 35 words. \
        No exclamation marks. No profanity. Never mention the person's body, weight, looks or worth. \
        Never tell them to push through pain or injury. Plain words, no military words. \
        Write every number as digits. End pointed at the next set or the next day. Reply with the line only.
        """
        switch mode {
        case .off:
            return common
        case .coaching:
            return common + " Tone: calm and encouraging. Recognize a real win from the numbers, or look ahead to what is left. No guilt and no blame; never mention missed or snoozed sets."
        case .push:
            return common + " Tone: hard and relentless, a coach who expects more and says so, never a cheerleader. Two or three short, hard sentences, up to 35 words. Talk about discipline, discomfort, excuses, keeping your word, and the mind quitting before you do. Use at most one number, and don't just recite the counts. Never praise unless every set is done, and then only in a few words. Call out excuses, snoozes and missed sets as broken commitments. Challenge them; never insult them or mention their body."
        }
    }

    public static func prompt(facts f: CoachFacts, mode: CoachMode) -> String {
        var lines = [
            f.moment == .afterSet ? "Moment: just finished a set." : "Moment: just finished the whole day.",
            "Day \(f.day) of 14, then a final test on Day 15.",
            "Sets done today: \(f.setsDone) of \(f.setsTotal).",
            "Sets left today: \(f.setsLeft).",
            "Push-ups this set: \(f.repsThisSet).",
            "Push-ups today: \(f.repsToday) of \(f.repsPlannedToday) planned.",
            "Starting max on Day 1: \(f.dayOneMax).",
        ]
        // Coaching never mentions missed or snoozed sets, so it is never told about them.
        if mode == .push {
            lines.insert("Sets missed today: \(f.setsMissed).", at: 3)
            lines.append("Times they pushed a set back today: \(f.snoozesToday).")
        }
        if f.bestEarlierDay > 0 { lines.append("Best earlier day: \(f.bestEarlierDay) push-ups.") }
        if f.testTomorrow {
            lines.append(f.day == 7 ? "Tomorrow is the re-test, with no sets." : "Tomorrow is the final test, with no sets.")
        }
        return lines.joined(separator: "\n")
    }
}
