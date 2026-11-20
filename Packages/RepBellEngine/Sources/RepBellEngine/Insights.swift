import Foundation

/// Numbers and plain-language observations drawn from what the person actually logged.
public struct RunInsights: Equatable, Sendable {
    public struct Max: Equatable, Sendable {
        public var day: Int
        public var reps: Int
    }

    public enum Link: String, Equatable, Sendable {
        case schedule
    }

    public struct Observation: Equatable, Sendable {
        public var text: String
        public var link: Link?
    }

    public var maxes: [Max] = []
    /// Gain from the Day 1 test to the latest test, by the same whole-number rule as the result card.
    public var gainPercent: Int?
    /// The test day the gain runs to (8 or 15).
    public var gainThroughDay: Int?
    /// Forward-looking facts for Progress (roadmap item 5). True, from the person's own log, never blaming.
    public var ahead: [String] = []
    public var setsDone = 0
    public var setsMissed = 0
    public var onTimePercent: Int?
    public var medianResponseMinutes: Int?
    public var snoozes = 0
    public var bestPerfectStreak = 0
    public var pushUps = 0
    public var observations: [Observation] = []
}

public enum InsightsEngine {
    /// A set counts as on time when it was logged within this many minutes of its scheduled time.
    public static let onTimeMinutes = 10
    /// Observations need at least this many data points in each group they compare.
    static let minimumSample = 5

    public static func run(_ input: RunInput, now: CivilDateTime) -> RunInsights {
        let resolved = ScheduleEngine.resolve(input, now: now)
        var out = RunInsights()

        for day in [1, 8, 15] {
            if let reps = resolved.day(day)?.testReps {
                out.maxes.append(.init(day: day, reps: reps))
            }
        }
        if let first = out.maxes.first, let last = out.maxes.last, out.maxes.count > 1, first.reps > 0 {
            out.gainPercent = Copy.percentGain(from: first.reps, to: last.reps)
            out.gainThroughDay = last.day
        }

        let sets = resolved.days.filter { $0.number <= 14 }.flatMap(\.sets)
        out.setsDone = sets.filter { $0.status == .done }.count
        out.setsMissed = sets.filter { $0.status == .missed }.count
        out.pushUps = resolved.loggedSetReps

        // Response time: scheduled time to the moment the set was logged.
        var gridByID: [String: CivilDateTime] = [:]
        for set in sets { gridByID[set.id] = set.grid }
        var responses: [(minutes: Int, hour: Int)] = []
        for event in input.events {
            switch event {
            case let .done(day, index, at):
                guard let grid = gridByID["\(day).\(index)"] else { continue }
                responses.append((max(0, grid.minutes(until: at)), grid.minutes / 60))
            case .snooze:
                out.snoozes += 1
            default:
                break
            }
        }
        if !responses.isEmpty {
            let onTime = responses.filter { $0.minutes <= onTimeMinutes }.count
            out.onTimePercent = Int((Double(onTime) / Double(responses.count) * 100).rounded())
            out.medianResponseMinutes = median(responses.map(\.minutes))
        }

        // Longest run of consecutive days where every set was done.
        var streak = 0
        for day in resolved.days where day.number <= 14 && !day.sets.isEmpty {
            let finished = day.sets.allSatisfy { $0.status != .upcoming }
            guard finished else { break }
            if day.missedCount == 0 {
                streak += 1
                out.bestPerfectStreak = max(out.bestPerfectStreak, streak)
            } else {
                streak = 0
            }
        }

        out.observations = observations(out, sets: sets, responses: responses)
        out.ahead = ahead(resolved, now: now, insights: out)
        return out
    }

    /// What's coming and what the work so far adds up to. Facts only; nothing about missed sets.
    static func ahead(_ resolved: ResolvedRun, now: CivilDateTime, insights: RunInsights) -> [String] {
        var lines: [String] = []
        let today = resolved.input.dayNumber(on: now.date)

        if let gain = insights.gainPercent, gain > 0, let through = insights.gainThroughDay {
            lines.append("Up \(gain)% since Day 1, measured on Day \(through).")
        }

        let program = resolved.days.filter { $0.number <= 14 }
        if let best = program.filter({ $0.loggedReps > 0 }).max(by: { $0.loggedReps < $1.loggedReps }) {
            lines.append("Biggest day so far: Day \(best.number), \(Copy.grouped(best.loggedReps)) push-ups.")
        }

        if let today, today <= 14 {
            let left = program.filter { $0.number >= today }.flatMap(\.sets).filter { $0.status == .upcoming }
            let reps = left.reduce(0) { $0 + $1.reps }
            if !left.isEmpty {
                let sets = left.count == 1 ? "1 set" : "\(left.count) sets"
                lines.append("\(sets) left in this run, about \(Copy.grouped(reps)) push-ups, before the final test.")
            }
            if today < 14, let next = resolved.day(today + 1) {
                if next.isTest {
                    lines.append("Tomorrow, Day \(next.number): your re-test.")
                } else if !next.sets.isEmpty {
                    lines.append("Tomorrow, Day \(next.number): \(next.sets.count) sets of \(next.reps).")
                }
            } else if today == 14 {
                lines.append("Tomorrow: the final test.")
            }
            let daysLeft = 15 - today
            if daysLeft > 1 {
                lines.append("\(daysLeft) days to the final test.")
            }
        }
        return lines
    }

    private static func observations(_ insights: RunInsights, sets: [ScheduledSet], responses: [(minutes: Int, hour: Int)]) -> [RunInsights.Observation] {
        var notes: [RunInsights.Observation] = []

        if let gain = insights.gainPercent, gain > 0, let last = insights.maxes.last {
            notes.append(.init(text: "Your max is up \(gain)% since Day 1, to \(last.reps).", link: nil))
        }

        // Where the misses cluster.
        let missed = sets.filter { $0.status == .missed }
        if missed.count >= 4 {
            let evening = missed.filter { $0.grid.minutes >= 17 * 60 }.count
            let morning = missed.filter { $0.grid.minutes < 12 * 60 }.count
            if Double(evening) / Double(missed.count) >= 0.5 {
                notes.append(.init(text: "Most of your missed sets come after 5 p.m. An earlier end of day would cut them.", link: .schedule))
            } else if Double(morning) / Double(missed.count) >= 0.5 {
                notes.append(.init(text: "Most of your missed sets come before noon. A later wake time would cut them.", link: .schedule))
            }
        }

        // Fastest part of the day.
        let parts: [(name: String, range: Range<Int>)] = [("morning", 0..<12), ("afternoon", 12..<17), ("evening", 17..<24)]
        let medians = parts.compactMap { part -> (String, Int)? in
            let group = responses.filter { part.range.contains($0.hour) }.map(\.minutes)
            guard group.count >= minimumSample else { return nil }
            return (part.name, median(group))
        }
        if medians.count >= 2, let fastest = medians.min(by: { $0.1 < $1.1 }), let slowest = medians.max(by: { $0.1 < $1.1 }), slowest.1 - fastest.1 >= 3 {
            let minutes = fastest.1 == 1 ? "1 minute" : "\(fastest.1) minutes"
            notes.append(.init(text: "You answer alerts fastest in the \(fastest.0), typically within \(minutes).", link: nil))
        }

        if insights.snoozes >= 3 {
            notes.append(.init(text: "You've pushed \(insights.snoozes) sets back with In 10.", link: nil))
        }
        if insights.bestPerfectStreak >= 2 {
            notes.append(.init(text: "Longest run of perfect days: \(insights.bestPerfectStreak).", link: nil))
        }
        return notes
    }

    static func median(_ values: [Int]) -> Int {
        let sorted = values.sorted()
        guard !sorted.isEmpty else { return 0 }
        let mid = sorted.count / 2
        return sorted.count % 2 == 1 ? sorted[mid] : (sorted[mid - 1] + sorted[mid]) / 2
    }
}

public extension ScheduleEngine {
    /// What a wake or end-of-day change would do to today's remaining sets, before it's applied.
    static func previewWindowChange(_ input: RunInput, wake: ClockTime, bed: ClockTime, at now: CivilDateTime) -> (before: Int, after: Int, last: ClockTime?) {
        let today = { (run: RunInput) -> [ScheduledSet] in
            let resolved = ScheduleEngine.resolve(run, now: now)
            guard let number = run.dayNumber(on: now.date), let day = resolved.day(number) else { return [] }
            return day.sets.filter { $0.status == .upcoming && $0.grid > now }
        }
        let before = today(input)
        var changed = input
        changed.events.append(.window(wake: wake, bed: bed, at: now))
        let after = today(changed)
        let last = after.map(\.grid).max().map { ClockTime(hour: $0.minutes / 60 % 24, minute: $0.minutes % 60) }
        return (before.count, after.count, last)
    }
}
