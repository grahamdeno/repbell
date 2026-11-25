import XCTest
@testable import RepBellEngine

/// Roadmap item 17: Coach voice lines follow the rules for their mode, from the person's own numbers only.
final class CoachVoiceTests: XCTestCase {
    private func facts(_ moment: CoachFacts.Moment = .afterSet, day: Int = 3, done: Int = 4, total: Int = 16,
                       missed: Int = 0, snoozes: Int = 0, best: Int = 0, full: Int = 0) -> CoachFacts {
        CoachFacts(moment: moment, day: day, setsDone: done, setsTotal: total, setsMissed: missed, repsThisSet: 24,
                   repsToday: done * 24, repsPlannedToday: total * 24, snoozesToday: snoozes, bestEarlierDay: best,
                   fullDaysBefore: full, dayOneMax: 40)
    }

    private var grid: [CoachFacts] {
        var all: [CoachFacts] = []
        for moment in [CoachFacts.Moment.afterSet, .dayDone] {
            for day in [1, 3, 9, 13, 14] {
                for done in [1, 8, 16] {
                    for missed in [0, 2] where done + missed <= 16 {
                        for snoozes in [0, 3] {
                            for best in [0, 100, 900] {
                                all.append(facts(moment, day: day, done: done, missed: missed, snoozes: snoozes,
                                                 best: best, full: day > 1 ? day - 1 : 0))
                            }
                        }
                    }
                }
            }
        }
        return all
    }

    // Every written line passes its own mode's rules, for every kind of day.
    func testWrittenLinesPassTheRules() {
        for mode in [CoachMode.coaching, .push] {
            for f in grid {
                let options = CoachVoice.writtenOptions(mode: mode, facts: f)
                XCTAssertFalse(options.isEmpty)
                for line in options {
                    XCTAssertTrue(CoachVoice.accepts(line, mode: mode, facts: f), "\(mode): \(line)")
                }
            }
        }
    }

    // Off shows nothing.
    func testOffHasNoLine() {
        XCTAssertNil(CoachVoice.writtenLine(mode: .off, facts: facts()))
    }

    // Coaching never carries guilt, even on a day with misses and snoozes.
    func testCoachingHasNoGuilt() {
        let f = facts(missed: 3, snoozes: 2)
        for line in CoachVoice.writtenOptions(mode: .coaching, facts: f) {
            XCTAssertFalse(line.lowercased().contains("miss"), line)
        }
        for line in ["You missed 3 today. No excuses.", "Missing sets happens.", "You snoozed 2.", "Skipped one.",
                     "You fell behind."] {
            XCTAssertFalse(CoachVoice.accepts(line, mode: .coaching, facts: f), line)
        }
    }

    // Push may name a missed set as a broken commitment.
    func testPushNamesMissedSets() {
        let f = facts(done: 3, missed: 2)
        XCTAssertTrue(CoachVoice.writtenOptions(mode: .push, facts: f).allSatisfy { $0.contains("2") })
        XCTAssertTrue(CoachVoice.accepts("You missed 2. Don't miss the next one.", mode: .push, facts: f))
    }

    // Push limits: no profanity, nothing about the body or worth, nothing urging past pain or injury.
    func testPushLimits() {
        let f = facts()
        for line in ["Get the damn next set.", "Burn that fat off.", "You look pathetic.",
                     "Push through the pain.", "Ignore the injury.", "Back in the drill, soldier.",
                     "Dammit, move.", "Fight for it."] {
            XCTAssertFalse(CoachVoice.accepts(line, mode: .push, facts: f), line)
        }
        XCTAssertTrue(CoachVoice.accepts("Nobody's doing them for you. Get the next one.", mode: .push, facts: f))
    }

    // No exclamation marks, no made-up numbers, no long lines.
    func testFormatAndNumbers() {
        let f = facts()
        XCTAssertFalse(CoachVoice.accepts("Great set!", mode: .coaching, facts: f))
        XCTAssertFalse(CoachVoice.accepts("You did 500 today.", mode: .coaching, facts: f))
        XCTAssertTrue(CoachVoice.accepts("You did 96 today.", mode: .coaching, facts: f))
        XCTAssertFalse(CoachVoice.accepts("You did twenty more.", mode: .coaching, facts: f))
        XCTAssertFalse(CoachVoice.accepts(String(repeating: "Keep going. ", count: 20), mode: .coaching, facts: f))
    }

    // The prompt carries numbers only, and each mode's instructions name its tone and limits.
    func testPromptIsNumbersOnly() {
        let push = CoachVoice.prompt(facts: facts(missed: 2, snoozes: 1, best: 100, full: 2), mode: .push)
        XCTAssertTrue(push.contains("Push-ups today: 96 of 384 planned."))
        XCTAssertTrue(push.contains("Best earlier day: 100"))
        XCTAssertTrue(push.contains("Sets missed today: 2."))
        let coaching = CoachVoice.prompt(facts: facts(missed: 2, snoozes: 1), mode: .coaching)
        XCTAssertFalse(coaching.contains("missed"))
        XCTAssertFalse(coaching.contains("pushed a set back"))
        XCTAssertTrue(CoachVoice.instructions(mode: .coaching).contains("digits"))
        XCTAssertTrue(CoachVoice.instructions(mode: .push).contains("never insult"))
        XCTAssertTrue(CoachVoice.instructions(mode: .coaching).contains("No guilt"))
        XCTAssertTrue(CoachVoice.instructions(mode: .push).contains("pain or injury"))
    }

    // Facts come from the resolved run: today's counts, the best earlier day and the full days before.
    func testFactsFromRun() {
        let start = CivilDate(year: 2026, month: 11, day: 16)
        let input = RunInput(dayOneMax: 40, wake: ClockTime(hour: 7), bed: ClockTime(hour: 23), start: start)
        let run = ScheduleEngine.resolve(input, now: CivilDateTime(date: start.addingDays(2), hour: 12, minute: 0))
        guard let day3 = run.day(3) else { return XCTFail("no day 3") }
        let f = CoachFacts.make(run: run, day: 3, repsThisSet: day3.reps, dayOneMax: 40, moment: .afterSet)
        XCTAssertEqual(f?.setsTotal, day3.sets.count)
        XCTAssertEqual(f?.dayOneMax, 40)
        XCTAssertEqual(f?.daysToGo, 12)
    }

    // Plurals read right with one set left, one missed, one snooze.
    func testPluralsAndTestDays() {
        let one = facts(done: 14, total: 16, missed: 1, snoozes: 1)
        for line in CoachVoice.writtenOptions(mode: .push, facts: one) + CoachVoice.writtenOptions(mode: .coaching, facts: one) {
            XCTAssertFalse(line.contains("1 sets"), line)
            XCTAssertFalse(line.contains("Those sets"), line)
        }
        for line in CoachVoice.writtenOptions(mode: .push, facts: facts(.dayDone, done: 15, missed: 1)) {
            XCTAssertFalse(line.contains("1 times"), line)
        }
        let dayBeforeRetest = facts(.dayDone, day: 7, done: 16)
        XCTAssertTrue(CoachVoice.writtenOptions(mode: .push, facts: dayBeforeRetest).allSatisfy { $0.contains("re-test") })
        XCTAssertTrue(CoachVoice.writtenOptions(mode: .coaching, facts: facts(.dayDone, day: 14, done: 16))
            .allSatisfy { $0.contains("final test") })
    }

    // With a coach line the person clears the celebration; only then can a desk stretch come up.
    func testCelebrationWaitsForATapWithACoachLine() {
        XCTAssertNil(CelebrationTiming.autoDismiss(dayComplete: false, voiceOverRunning: false, coachLine: true))
        XCTAssertNil(CelebrationTiming.autoDismiss(dayComplete: true, voiceOverRunning: false, coachLine: true))
        XCTAssertEqual(CelebrationTiming.autoDismiss(dayComplete: false, voiceOverRunning: false, coachLine: false),
                       CelebrationTiming.perSet)
    }

    // On the long days (Day 9 about 46 sets, Day 10 about 61) no Push line repeats within 36 sets in a row,
    // a line shows at most twice in a day, and the general lines lean on attitude, not counts.
    func testPushVariesAcrossALongDay() {
        XCTAssertGreaterThanOrEqual(CoachVoice.pushGrit.count, 36)
        XCTAssertEqual(Set(CoachVoice.pushGrit).count, CoachVoice.pushGrit.count)
        for (day, total) in [(9, 46), (10, 61)] {
            var seen: [String] = []
            for done in 1..<total {
                seen.append(CoachVoice.writtenLine(mode: .push, facts: facts(day: day, done: done, total: total)) ?? "")
            }
            for start in 0..<max(seen.count - 35, 1) {
                let window = seen[start..<min(start + 36, seen.count)]
                XCTAssertEqual(Set(window).count, window.count, "day \(day) repeats within 36 sets")
            }
            let counts = Dictionary(seen.map { ($0, 1) }, uniquingKeysWith: +)
            XCTAssertLessThanOrEqual(counts.values.max() ?? 0, 2)
        }
        XCTAssertTrue(CoachVoice.pushGrit.allSatisfy { !$0.contains(where: \.isNumber) })
    }

    // A snooze or a miss is called out every third set, not on every set for the rest of the day.
    func testCallOutsDontTakeOverTheDay() {
        let lines = (1...12).map { done in
            CoachVoice.writtenLine(mode: .push, facts: facts(day: 9, done: done, total: 46, snoozes: 1)) ?? ""
        }
        XCTAssertEqual(lines.filter { $0.contains("pushed the bell back") }.count, 4)
    }

    // Push never praises a day with misses.
    func testPushDoesNotPraiseMisses() {
        for line in CoachVoice.writtenOptions(mode: .push, facts: facts(.dayDone, done: 14, missed: 2)) {
            let lower = line.lowercased()
            for praise in ["good", "great", "nice", "well done", "proud"] {
                XCTAssertFalse(lower.contains(praise), line)
            }
        }
        XCTAssertTrue(CoachVoice.instructions(mode: .push).contains("Never praise"))
    }
}
