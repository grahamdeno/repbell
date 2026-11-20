import XCTest
@testable import RepBellEngine

/// Build D (daily loop and glance) and roadmap item 5 (Progress).
final class DailyLoopTests: XCTestCase {
    private let start = CivilDate(year: 2026, month: 11, day: 16)

    private func at(day: Int, _ hour: Int, _ minute: Int) -> CivilDateTime {
        CivilDateTime(date: start.addingDays(day - 1), hour: hour, minute: minute)
    }

    private func input(_ events: [LogEvent] = []) -> RunInput {
        RunInput(dayOneMax: 40, wake: ClockTime(hour: 7), bed: ClockTime(hour: 23), start: start, events: events)
    }

    private let dayOneTest: LogEvent = .test(day: 1, reps: 40, at: CivilDateTime(date: CivilDate(year: 2026, month: 11, day: 16), hour: 7, minute: 5))

    // Item 2: 1.5 s per set, longer for a finished day, and no timeout with VoiceOver on.
    func testItem2_celebrationTiming() {
        XCTAssertEqual(CelebrationTiming.autoDismiss(dayComplete: false, voiceOverRunning: false), 1.5)
        XCTAssertGreaterThan(CelebrationTiming.autoDismiss(dayComplete: true, voiceOverRunning: false) ?? 0, 1.5)
        XCTAssertNil(CelebrationTiming.autoDismiss(dayComplete: false, voiceOverRunning: true))
        XCTAssertNil(CelebrationTiming.autoDismiss(dayComplete: true, voiceOverRunning: true))
    }

    // Item 2: the finished-day haptics come in bursts that build to the strongest and ease back.
    func testItem2_hapticsBuildAndEase() {
        let hits = CelebrationHaptics.dayComplete()
        let levels = hits.map(\.intensity)
        let peak = try! XCTUnwrap(levels.max())
        let firstPeak = try! XCTUnwrap(levels.firstIndex(of: peak))
        XCTAssertEqual(peak, 1.0)
        XCTAssertLessThan(levels.first!, peak)
        XCTAssertLessThan(levels.last!, peak)
        XCTAssertEqual(levels[..<firstPeak].sorted(), Array(levels[..<firstPeak]))
        XCTAssertEqual(hits.map(\.time).sorted(), hits.map(\.time))
        XCTAssertGreaterThanOrEqual(hits.count, 9)
    }

    // Item 3: Busy is labelled "Busy for 1 hour"; the strip says when alerts return and how many sets it missed.
    func testItem3_busyLabelAndStrip() {
        XCTAssertEqual(Copy.busy, "Busy for 1 hour")
        XCTAssertFalse(Copy.busy.lowercased().contains("skip"))
        let busyAt = at(day: 2, 13, 20)
        let run = input([dayOneTest, .busy(at: busyAt)])
        let active = try! XCTUnwrap(ScheduleEngine.activeBusy(run, now: at(day: 2, 13, 25)))
        XCTAssertEqual(active.until, at(day: 2, 14, 20))
        XCTAssertEqual(active.skipped, 1)
        XCTAssertEqual(Copy.busyStrip(until: active.until, skipped: 1), "Alerts off until 2:20 p.m. · 1 set counts as missed")
        XCTAssertNil(ScheduleEngine.activeBusy(run, now: at(day: 2, 14, 21)))
    }

    // Item 3: Undo is removing the busy event; the sets come back.
    func testItem3_undoRestoresSets() {
        let busyAt = at(day: 2, 13, 20)
        var run = input([dayOneTest, .busy(at: busyAt)])
        let now = at(day: 2, 13, 25)
        XCTAssertEqual(ScheduleEngine.resolve(run, now: now).day(2)?.sets.first { $0.grid == at(day: 2, 14, 0) }?.status, .missed)
        run.events.removeAll { if case .busy = $0 { return true } else { return false } }
        XCTAssertEqual(ScheduleEngine.resolve(run, now: now).day(2)?.sets.first { $0.grid == at(day: 2, 14, 0) }?.status, .upcoming)
    }

    // UX-14: short strokes are exact; long strokes go faster, in both directions.
    func testUX14_counterAccelerates() {
        XCTAssertEqual(CounterMath.reps(forDrag: 14), 1)
        XCTAssertEqual(CounterMath.reps(forDrag: 84), 6)
        XCTAssertEqual(CounterMath.reps(forDrag: -84), -6)
        XCTAssertGreaterThanOrEqual(CounterMath.reps(forDrag: 400), 50)
        XCTAssertEqual(CounterMath.reps(forDrag: -400), -CounterMath.reps(forDrag: 400))
    }

    // UX-15: the widget has a state for each kind of morning, never "0 of 0".
    func testUX15_widgetStates() {
        XCTAssertEqual(WidgetState.make(run: nil, now: at(day: 1, 6, 0)), .notStarted)
        let fresh = PersistedRun(input: input())
        XCTAssertEqual(WidgetState.make(run: fresh, now: at(day: 0, 20, 0)), .startsOn(wake: ClockTime(hour: 7)))
        XCTAssertEqual(WidgetState.make(run: fresh, now: at(day: 1, 6, 30)), .testToday(day: 1, wake: ClockTime(hour: 7)))
        let paused = PersistedRun(input: input([dayOneTest]), pausedAt: at(day: 3, 9, 0))
        XCTAssertEqual(WidgetState.make(run: paused, now: at(day: 3, 10, 0)), .paused(day: 3))
        if case .next(let day, _, let reps) = WidgetState.make(run: PersistedRun(input: input([dayOneTest])), now: at(day: 2, 7, 30)) {
            XCTAssertEqual(day, 2)
            XCTAssertEqual(reps, 20)
        } else {
            XCTFail("expected the next set")
        }
        if case .dayDone(let day, _, let total, _) = WidgetState.make(run: PersistedRun(input: input([dayOneTest])), now: at(day: 2, 23, 30)) {
            XCTAssertEqual(day, 2)
            XCTAssertGreaterThan(total, 0)
        } else {
            XCTFail("expected end of day")
        }
        XCTAssertEqual(WidgetState.make(run: PersistedRun(input: input(), ended: true), now: at(day: 5, 9, 0)), .finished)
        let lines = Copy.widgetLines(.testToday(day: 8, wake: ClockTime(hour: 7)))
        XCTAssertFalse(lines.big.contains("0 of 0"))
        XCTAssertTrue(lines.title.contains("Test today"))
    }

    // UX-25: the test hero says the test comes first, then logging.
    func testUX25_testHeroWords() {
        XCTAssertEqual(Copy.startTest, "Log my test")
        XCTAssertTrue(Copy.testHeroBody.contains("Then log"))
    }

    // UX-31, UX-41: one percent rule for Progress and the result card, labelled with its end day.
    func testUX31_oneGainRule() {
        let run = input([
            .test(day: 1, reps: 45, at: at(day: 1, 7, 5)),
            .test(day: 8, reps: 65, at: at(day: 8, 7, 5)),
        ])
        let insights = InsightsEngine.run(run, now: at(day: 8, 9, 0))
        XCTAssertEqual(insights.gainPercent, Copy.percentGain(from: 45, to: 65))
        XCTAssertEqual(insights.gainPercent, 44)
        XCTAssertEqual(insights.gainThroughDay, 8)
    }

    // UX-38: Progress never shows "Day 15 of 14".
    func testUX38_dayLabel() {
        XCTAssertEqual(Copy.progressDay(6, ended: false), "6 of 14")
        XCTAssertEqual(Copy.progressDay(15, ended: false), "Final test")
        XCTAssertEqual(Copy.progressDay(9, ended: true), "Done")
        XCTAssertFalse(Copy.progressDay(15, ended: false).contains("of 14"))
    }

    // UX-36: house style for times.
    func testUX36_timesUsePeriods() {
        var events: [LogEvent] = [dayOneTest]
        // Miss four evening sets on Day 2 by logging nothing after 5 p.m. and resolving at night.
        let resolved = ScheduleEngine.resolve(input(events), now: at(day: 2, 7, 0))
        for set in resolved.day(2)!.sets where set.grid.minutes < 17 * 60 {
            events.append(.done(day: 2, index: set.index, at: set.grid))
        }
        let insights = InsightsEngine.run(input(events), now: at(day: 2, 23, 30))
        XCTAssertFalse(insights.observations.contains { $0.text.contains(" pm") })
        XCTAssertTrue(insights.observations.contains { $0.text.contains("5 p.m.") })
    }

    // Item 5 (requirement): Progress keeps all eight numbers, in factual wording.
    func testItem5_progressKeepsAllNumbers() {
        XCTAssertEqual(Copy.ProgressLabel.all, [
            "Day", "Push-ups", "Sets done", "Sets missed", "On time", "Typical response", "Perfect days in a row", "Snoozed",
        ])
        let run = input([dayOneTest])
        let insights = InsightsEngine.run(run, now: at(day: 1, 12, 0))
        XCTAssertGreaterThanOrEqual(insights.bestPerfectStreak, 0)
        XCTAssertGreaterThanOrEqual(insights.snoozes, 0)
    }

    // Item 5: Progress explains what the numbers mean with true, forward-looking facts that never blame.
    func testItem5_aheadFacts() {
        let resolved = ScheduleEngine.resolve(input([dayOneTest]), now: at(day: 2, 7, 0))
        var events: [LogEvent] = [dayOneTest]
        for set in resolved.day(2)!.sets.prefix(5) {
            events.append(.done(day: 2, index: set.index, at: set.grid))
        }
        let insights = InsightsEngine.run(input(events), now: at(day: 2, 12, 0))
        XCTAssertTrue(insights.ahead.contains { $0.hasPrefix("Biggest day so far: Day 2") })
        XCTAssertTrue(insights.ahead.contains { $0.contains("left in this run") })
        XCTAssertTrue(insights.ahead.contains { $0.hasPrefix("Tomorrow, Day 3:") })
        XCTAssertTrue(insights.ahead.contains("13 days to the final test."))
        for line in insights.ahead {
            XCTAssertFalse(line.lowercased().contains("missed"), line)
            XCTAssertFalse(line.contains("!"), line)
        }
    }

    // Item 5: the facts change on the eve of a test and the last day.
    func testItem5_aheadAroundTests() {
        let day7 = InsightsEngine.run(input([dayOneTest]), now: at(day: 7, 9, 0))
        XCTAssertTrue(day7.ahead.contains("Tomorrow, Day 8: your re-test."))
        let day14 = InsightsEngine.run(input([dayOneTest]), now: at(day: 14, 9, 0))
        XCTAssertTrue(day14.ahead.contains("Tomorrow: the final test."))
    }
}
