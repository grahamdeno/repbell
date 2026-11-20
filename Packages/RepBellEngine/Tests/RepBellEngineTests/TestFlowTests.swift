import XCTest
@testable import RepBellEngine

/// Build B: no dead ends in the test flow (UX-2, UX-28, UX-29) and the ended-run heading (UX-18).
final class TestFlowTests: XCTestCase {
    private let start = CivilDate(year: 2026, month: 11, day: 16)

    private func run(events: [LogEvent] = [], pausedAt: CivilDateTime? = nil, ended: Bool = false) -> PersistedRun {
        PersistedRun(
            input: RunInput(dayOneMax: 40, wake: ClockTime(hour: 7), bed: ClockTime(hour: 23), start: start, events: events),
            pausedAt: pausedAt,
            ended: ended
        )
    }

    private func at(day: Int, _ hour: Int, _ minute: Int) -> CivilDateTime {
        CivilDateTime(date: start.addingDays(day - 1), hour: hour, minute: minute)
    }

    // UX-2: on a test morning the counter opens by itself, within 90 minutes of wake.
    func testUX2_counterOpensOnTestMorningWithinNinetyMinutes() {
        XCTAssertEqual(TestFlow.counterToOpen(run: run(), now: at(day: 1, 7, 30), deferredOn: nil), 1)
        XCTAssertEqual(TestFlow.counterToOpen(run: run(), now: at(day: 1, 8, 30), deferredOn: nil), 1)
        XCTAssertNil(TestFlow.counterToOpen(run: run(), now: at(day: 1, 8, 31), deferredOn: nil))
        XCTAssertNil(TestFlow.counterToOpen(run: run(), now: at(day: 1, 6, 59), deferredOn: nil))
    }

    // UX-2: after "Not yet", the counter doesn't open by itself again that day; Today keeps the test.
    func testUX2_notYetStopsTheCounterOpeningAgainThatDay() {
        let now = at(day: 1, 7, 30)
        XCTAssertNil(TestFlow.counterToOpen(run: run(), now: now, deferredOn: now.date))
    }

    // UX-2: "Not yet" on an earlier date doesn't stop the next test morning.
    func testUX2_notYetOnAnEarlierDateDoesNotCarryOver() {
        let day8 = at(day: 8, 7, 10)
        let events: [LogEvent] = [.test(day: 1, reps: 40, at: at(day: 1, 7, 5))]
        XCTAssertEqual(TestFlow.counterToOpen(run: run(events: events), now: day8, deferredOn: start), 8)
    }

    // UX-2: the counter never opens by itself on an ordinary day, after the test, or when paused or ended.
    func testUX2_counterStaysClosedOtherwise() {
        XCTAssertNil(TestFlow.counterToOpen(run: run(), now: at(day: 2, 7, 10), deferredOn: nil))
        let logged: [LogEvent] = [.test(day: 1, reps: 40, at: at(day: 1, 7, 5))]
        XCTAssertNil(TestFlow.counterToOpen(run: run(events: logged), now: at(day: 1, 7, 30), deferredOn: nil))
        XCTAssertNil(TestFlow.counterToOpen(run: run(pausedAt: at(day: 1, 6, 0)), now: at(day: 1, 7, 30), deferredOn: nil))
        XCTAssertNil(TestFlow.counterToOpen(run: run(ended: true), now: at(day: 1, 7, 30), deferredOn: nil))
        XCTAssertNil(TestFlow.counterToOpen(run: nil, now: at(day: 1, 7, 30), deferredOn: nil))
    }

    // UX-28: Done can't act at 0.
    func testUX28_doneDisabledAtZero() {
        XCTAssertFalse(TestFlow.canSubmit(count: 0))
        XCTAssertTrue(TestFlow.canSubmit(count: 1))
    }

    // UX-29: the Day 15 number can be fixed; the test keeps its time and the result shows the new number.
    func testUX29_fixDay15Number() {
        let day15 = at(day: 15, 7, 5)
        var input = run(events: [
            .test(day: 1, reps: 40, at: at(day: 1, 7, 5)),
            .test(day: 15, reps: 6, at: day15),
        ]).input
        XCTAssertTrue(input.correctTest(day: 15, reps: 60))
        XCTAssertEqual(ScheduleEngine.resolve(input, now: at(day: 15, 9, 0)).day(15)?.testReps, 60)
        XCTAssertEqual(input.events.last?.at, day15)
        XCTAssertEqual(input.events.count, 2)
    }

    // UX-29: correcting Day 1 also updates the stored Day 1 max; nothing changes without a logged test or at 0.
    func testUX29_correctionRules() {
        var input = run(events: [.test(day: 1, reps: 40, at: at(day: 1, 7, 5))]).input
        XCTAssertTrue(input.correctTest(day: 1, reps: 44))
        XCTAssertEqual(input.dayOneMax, 44)
        XCTAssertFalse(input.correctTest(day: 15, reps: 50))
        XCTAssertFalse(input.correctTest(day: 1, reps: 0))
        XCTAssertEqual(ScheduleEngine.resolve(input, now: at(day: 1, 9, 0)).day(1)?.testReps, 44)
    }

    // UX-18: an ended run is headed by the day it ended, never by the button's words.
    func testUX18_endedRunHeading() {
        XCTAssertEqual(Copy.runEnded(day: 6), "Run ended · Day 6")
        XCTAssertNotEqual(Copy.runEnded(day: 6), Copy.endTitle)
        XCTAssertFalse(Copy.endConfirmBody.contains("!"))
    }

    // UX-12: the alerts-denied screen says what happened and how to go on.
    func testUX12_deniedCopyGivesAWayOn() {
        XCTAssertTrue(Copy.alertsDeniedBody.contains("Settings"))
        XCTAssertFalse(Copy.startWithoutAlerts.isEmpty)
        XCTAssertNotEqual(Copy.alertsDeniedBody, Copy.alertsBody)
    }
}
