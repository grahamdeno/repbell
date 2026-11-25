import Foundation

/// Coach voice (roadmap item 17): one short line after a set or a finished day, from the person's own numbers.
public enum CoachMode: String, CaseIterable, Codable, Sendable {
    case off, coaching, push
}

/// The numbers a coach line may use. Numbers only: nothing a person typed ever reaches the model.
public struct CoachFacts: Equatable, Sendable {
    public enum Moment: String, Sendable { case afterSet, dayDone }

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
    // MARK: Rules every line must pass, written or generated

    static let profanity: Set<String> = ["fuck", "fucking", "shit", "damn", "hell", "ass", "bitch", "crap", "piss",
                                         "bastard"]
    /// Push limits: nothing about the body, looks or worth, and nothing that urges past pain or injury.
    /// Matched as the start of a word, so "nobody" and "toward" pass.
    static let neverSaidStems = ["fat", "weight", "body", "belly", "ugly", "looks", "worthless", "pathetic", "loser",
                                 "useless", "stupid", "pain", "injur", "hurt", "bleed", "puke", "soldier", "drill",
                                 "mission", "battle", "war"]
    /// Coaching carries no guilt.
    static let guiltWords: Set<String> = ["missed", "miss", "excuse", "excuses", "quit", "quitting", "soft", "lazy",
                                          "promise", "promised", "owe", "gone", "table", "nobody"]
    static let guiltPhrases = ["should have", "pushed back", "got away", "broke your", "broken"]

    /// Whether a line may be shown for this mode and these facts.
    public static func accepts(_ line: String, mode: CoachMode, facts: CoachFacts) -> Bool {
        let text = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, text.count <= 140, !text.contains("!"), !text.contains("\n") else { return false }
        let lower = text.lowercased()
        let words = lower.split { !$0.isLetter }.map(String.init)
        if words.contains(where: profanity.contains) { return false }
        if words.contains(where: { word in neverSaidStems.contains(where: word.hasPrefix) }) { return false }
        if mode == .coaching {
            if words.contains(where: guiltWords.contains) { return false }
            if guiltPhrases.contains(where: lower.contains) { return false }
        }
        // No made-up numbers: every number in the line is one of the person's own.
        let numbers = text.split { !$0.isNumber && $0 != "," }
            .compactMap { Int($0.replacingOccurrences(of: ",", with: "")) }
        return numbers.allSatisfy { facts.allowedNumbers.contains($0) }
    }

    // MARK: Written lines (used when the on-device model is unavailable, slow, or breaks a rule)

    public static func writtenLine(mode: CoachMode, facts f: CoachFacts) -> String? {
        let options = writtenOptions(mode: mode, facts: f)
        guard !options.isEmpty else { return nil }
        let seed = f.day * 31 + f.setsDone * 7 + f.setsMissed
        return options[seed % options.count]
    }

    static func writtenOptions(mode: CoachMode, facts f: CoachFacts) -> [String] {
        let days = f.daysToGo == 1 ? "1 day" : "\(f.daysToGo) days"
        switch (mode, f.moment) {
        case (.off, _):
            return []
        case (.coaching, .afterSet):
            var lines = [
                "\(f.repsToday) so far today. \(f.setsLeft) sets left, and each one moves you toward Day 15.",
                "Set \(f.setsDone) of \(f.setsTotal) is in. Keep the next one just as clean.",
                "That's \(f.setsDone) sets done today. Same form on the next one.",
            ]
            if f.setsLeft == 0 { lines = ["Set \(f.setsDone) of \(f.setsTotal) is in. That's the day's work."] }
            if f.bestEarlierDay > 0 && f.repsToday > f.bestEarlierDay {
                lines.append("\(f.repsToday) today already beats your best day of \(f.bestEarlierDay).")
            }
            if f.fullDaysBefore > 0 {
                lines.append("\(f.fullDaysBefore) full days behind you. Today is adding to that.")
            }
            return lines
        case (.coaching, .dayDone):
            var lines = [
                "Day \(f.day) done: \(f.repsToday) push-ups. \(days) to Day 15.",
                "You started at a max of \(f.dayOneMax). Days like this one build past it.",
            ]
            if f.daysToGo == 0 { lines[0] = "Day \(f.day) done: \(f.repsToday) push-ups. Test day is next." }
            if f.bestEarlierDay > 0 && f.repsToday > f.bestEarlierDay {
                lines.append("\(f.repsToday) is your best day yet, up from \(f.bestEarlierDay).")
            }
            return lines
        case (.push, .afterSet):
            if f.setsMissed > 0 {
                return ["\(f.setsMissed) missed today. That set is gone. Don't let the next one go with it.",
                        "You said every set. \(f.setsMissed) got away today. Not the next one."]
            }
            if f.snoozesToday > 0 {
                return ["You pushed back \(f.snoozesToday) today. When the bell rings next, be there."]
            }
            if f.setsLeft == 0 {
                return ["\(f.setsDone) of \(f.setsTotal). Every set done. That's the standard now."]
            }
            return [
                "\(f.setsDone) of \(f.setsTotal). That's not done. Next set, same standard.",
                "\(f.setsLeft) sets left. Nobody's doing them for you. Get the next one.",
                "\(f.repsToday) is a start. The day asks for \(f.repsPlannedToday). Go get the rest.",
            ]
        case (.push, .dayDone):
            if f.setsMissed > 0 {
                return ["\(f.setsDone) of \(f.setsTotal). You left \(f.setsMissed) on the table. Tomorrow you take every one."]
            }
            return [
                "\(f.setsTotal) of \(f.setsTotal). You did what you said you'd do. Do it again tomorrow.",
                "\(f.repsToday) today. That's the standard now. Don't come back with less.",
            ]
        }
    }

    // MARK: Prompt for the on-device model

    public static func instructions(mode: CoachMode) -> String {
        let common = """
        You write one line for a push-up app, shown right after the person logs a set or finishes a day. \
        Use only the numbers given and never invent a number. One or two short sentences, under 20 words. \
        No exclamation marks. No profanity. Never mention the person's body, weight, looks or worth. \
        Never tell them to push through pain or injury. Plain words, no military words. \
        End pointed at the next set or the next day. Reply with the line only.
        """
        switch mode {
        case .off:
            return common
        case .coaching:
            return common + " Tone: calm and encouraging. Recognize a real win from the numbers, or look ahead to what is left. No guilt and no blame; never mention missed or snoozed sets."
        case .push:
            return common + " Tone: blunt and demanding, a hard coach who holds people to their word. You may call a missed or snoozed set a broken commitment. Short, hard sentences. Challenge them; never insult them."
        }
    }

    public static func prompt(facts f: CoachFacts) -> String {
        var lines = [
            f.moment == .afterSet ? "Moment: just finished a set." : "Moment: just finished the whole day.",
            "Day \(f.day) of 14, then a final test on Day 15.",
            "Sets done today: \(f.setsDone) of \(f.setsTotal).",
            "Sets missed today: \(f.setsMissed).",
            "Sets left today: \(f.setsLeft).",
            "Push-ups this set: \(f.repsThisSet).",
            "Push-ups today: \(f.repsToday) of \(f.repsPlannedToday) planned.",
            "Times they pushed a set back today: \(f.snoozesToday).",
            "Starting max on Day 1: \(f.dayOneMax).",
        ]
        if f.bestEarlierDay > 0 { lines.append("Best earlier day: \(f.bestEarlierDay) push-ups.") }
        if f.fullDaysBefore > 0 { lines.append("Earlier days with every set done: \(f.fullDaysBefore).") }
        return lines.joined(separator: "\n")
    }
}
