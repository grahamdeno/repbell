#if DEBUG
import XCTest
@testable import RepBellEngine

/// The screenshot seeds put the real engine into each state. Run at 3 p.m., as the screenshot workflow does.
final class ScreenshotSeedsTests: XCTestCase {
    private var afternoon: Date {
        var parts = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        parts.hour = 15
        parts.minute = 0
        return Calendar.current.date(from: parts)!
    }

    private func today(_ state: String) -> (ScheduledDay, CivilDateTime)? {
        let now = CivilDateTime.local(afternoon)
        guard let run = ScreenshotSeeds.library(for: state, now: afternoon)?.library.current,
              let number = run.input.dayNumber(on: now.date),
              let day = ScheduleEngine.resolve(run.input, now: run.pausedAt ?? now).day(number) else { return nil }
        return (day, now)
    }

    func testSetDueHasADueSet() {
        let (day, now) = try! XCTUnwrap(today("today-set-due"))
        let next = try! XCTUnwrap(day.sets.first { $0.status == .upcoming })
        XCTAssertLessThanOrEqual(try! XCTUnwrap(next.alert), now)
        XCTAssertEqual(day.doneCount, 3)
    }

    func testBetweenSetsHasNothingDue() {
        let (day, now) = try! XCTUnwrap(today("today-between-sets"))
        let next = try! XCTUnwrap(day.sets.first { $0.status == .upcoming })
        XCTAssertGreaterThan(try! XCTUnwrap(next.alert), now)
    }

    func testMissedHasMisses() {
        let (day, _) = try! XCTUnwrap(today("today-missed"))
        XCTAssertGreaterThanOrEqual(day.missedCount, 2)
    }

    func testFinishedHasNothingLeft() {
        let (day, _) = try! XCTUnwrap(today("today-finished"))
        XCTAssertFalse(day.sets.isEmpty)
        XCTAssertFalse(day.sets.contains { $0.status == .upcoming })
        XCTAssertEqual(day.missedCount, 0)
    }

    func testBusyIsActive() {
        let run = try! XCTUnwrap(ScreenshotSeeds.library(for: "today-busy", now: afternoon)?.library.current)
        XCTAssertNotNil(ScheduleEngine.activeBusy(run.input, now: CivilDateTime.local(afternoon)))
    }

    func testTestMorningsAreWaitingForTheTest() {
        for state in ["today-day8-test", "today-day15"] {
            let (day, _) = try! XCTUnwrap(today(state), state)
            XCTAssertTrue(day.isTest, state)
            XCTAssertNil(day.testReps, state)
        }
    }

    func testResultAndProgressStates() {
        let (final, _) = try! XCTUnwrap(today("result-final"))
        XCTAssertEqual(final.testReps, 58)
        XCTAssertEqual(ScreenshotSeeds.library(for: "result-ended", now: afternoon)?.library.current?.ended, true)
        XCTAssertNotNil(ScreenshotSeeds.library(for: "progress", now: afternoon))
        XCTAssertNil(ScreenshotSeeds.library(for: "onboarding-promise", now: afternoon))
    }

    func testArgumentParsing() {
        XCTAssertEqual(ScreenshotSeeds.requestedState(["app", "-RBScreenshot", "today-busy"]), "today-busy")
        XCTAssertNil(ScreenshotSeeds.requestedState(["app"]))
    }
}
#endif
