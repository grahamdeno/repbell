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
}
