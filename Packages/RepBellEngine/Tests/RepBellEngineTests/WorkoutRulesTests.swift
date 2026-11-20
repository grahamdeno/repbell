import XCTest
@testable import RepBellEngine

/// Build E: Workouts doesn't compete with the program (UX-7).
final class WorkoutRulesTests: XCTestCase {
    private let start = CivilDate(year: 2026, month: 11, day: 16)

    private func run(ended: Bool = false, pausedAt: CivilDateTime? = nil) -> PersistedRun {
        PersistedRun(input: RunInput(dayOneMax: 40, wake: ClockTime(hour: 7), bed: ClockTime(hour: 23), start: start), pausedAt: pausedAt, ended: ended)
    }

    private func on(day: Int) -> CivilDateTime {
        CivilDateTime(date: start.addingDays(day - 1), hour: 12, minute: 0)
    }

    // UX-7: upper-body sessions wait during the 14 days, paused included.
    func testUX7_upperBodyHeldDuringRun() {
        for id in ["upper", "shoulders-arms", "kettlebell", "grip-pull"] {
            XCTAssertTrue(WorkoutRules.isHeld(id, run: run(), now: on(day: 3)), id)
            XCTAssertTrue(WorkoutRules.isHeld(id, run: run(pausedAt: on(day: 5)), now: on(day: 9)), id)
        }
    }

    // UX-7: the rest stay open, and everything opens after Day 14, after an ended run, or with no run.
    func testUX7_openOtherwise() {
        for id in ["lower-back", "core", "flow-45", "stretch", "easy-cardio"] {
            XCTAssertFalse(WorkoutRules.isHeld(id, run: run(), now: on(day: 3)), id)
        }
        XCTAssertFalse(WorkoutRules.isHeld("upper", run: run(), now: on(day: 15)))
        XCTAssertFalse(WorkoutRules.isHeld("upper", run: run(ended: true), now: on(day: 3)))
        XCTAssertFalse(WorkoutRules.isHeld("upper", run: nil, now: on(day: 3)))
        XCTAssertFalse(WorkoutRules.isHeld("upper", run: run(), now: on(day: 0)))
    }

    // Item 12: one Health workout per finished day with sets done, each written once.
    func testItem12_pushUpDaysToWrite() {
        let test: LogEvent = .test(day: 1, reps: 40, at: CivilDateTime(date: start, hour: 7, minute: 5))
        var input = run().input
        input.events = [test]
        let day2 = ScheduleEngine.resolve(input, now: on(day: 2)).day(2)!
        for set in day2.sets.prefix(3) {
            input.events.append(.done(day: 2, index: set.index, at: set.grid.adding(minutes: 2)))
        }
        let current = PersistedRun(input: input)
        // During Day 2 with sets left: nothing yet.
        XCTAssertTrue(PushUpHealth.pending(run: current, now: CivilDateTime(date: start.addingDays(1), hour: 11, minute: 0), written: []).isEmpty)
        // Day 3: Day 2 is over; one workout, 3 sets of 20, ending at the last log.
        let pending = PushUpHealth.pending(run: current, now: on(day: 3), written: [])
        XCTAssertEqual(pending.count, 1)
        XCTAssertEqual(pending.first?.day, 2)
        XCTAssertEqual(pending.first?.pushUps, 60)
        XCTAssertEqual(pending.first?.sets, 3)
        XCTAssertEqual(pending.first?.minutes, 3)
        XCTAssertEqual(pending.first?.end, day2.sets[2].grid.adding(minutes: 2))
        // Written once.
        XCTAssertTrue(PushUpHealth.pending(run: current, now: on(day: 3), written: Set(pending.map(\.key))).isEmpty)
        // Day 1 had no sets done, so nothing is written for it.
        XCTAssertFalse(pending.contains { $0.day == 1 })
        XCTAssertTrue(PushUpHealth.pending(run: nil, now: on(day: 3), written: []).isEmpty)
    }
}
