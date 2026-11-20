import XCTest
@testable import RepBellEngine

/// Roadmap item 13: day start and alarms that ring through silent.
final class RingPlanTests: XCTestCase {
    private let start = CivilDate(year: 2026, month: 11, day: 16)

    private func date(_ day: Int) -> CivilDate { start.addingDays(day - 1) }
    private func at(_ day: Int, _ hour: Int, _ minute: Int) -> CivilDateTime {
        CivilDateTime(date: date(day), hour: hour, minute: minute)
    }

    private func alerts(day: Int, every minutes: Int, from hour: Int = 7, count: Int) -> [QueuedAlert] {
        (0..<count).map { i in
            QueuedAlert(day: day, index: i + 1, reps: 15, total: count, at: at(day, hour, 0).adding(minutes: i * minutes))
        }
    }

    // Story 1: the first day rings; yesterday's choice is preselected; never choosing keeps yesterday's.
    func testStory1_choiceCarriesOver() {
        var state = RingState()
        XCTAssertEqual(state.preselected(on: date(1)), .ring)
        state.choose(.quiet, on: date(1))
        XCTAssertEqual(state.preselected(on: date(2)), .quiet)
        XCTAssertEqual(state.mode(on: date(3)), .quiet)
        state.choose(.ring, on: date(3))
        XCTAssertEqual(state.mode(on: date(4)), .ring)
        XCTAssertEqual(state.mode(on: date(2)), .quiet)
    }

    // Story 1: the day-start screen shows once a program day, after wake, while the run is going.
    func testStory1_dayStartScreen() {
        let run = PersistedRun(input: RunInput(dayOneMax: 40, wake: ClockTime(hour: 7), bed: ClockTime(hour: 23), start: start))
        var state = RingState()
        XCTAssertTrue(RingPlan.showDayStart(run: run, state: state, now: at(3, 7, 10)))
        XCTAssertFalse(RingPlan.showDayStart(run: run, state: state, now: at(3, 6, 50)))
        state.choose(.ring, on: date(3))
        XCTAssertFalse(RingPlan.showDayStart(run: run, state: state, now: at(3, 9, 0)))
        XCTAssertFalse(RingPlan.showDayStart(run: run, state: RingState(), now: at(15, 9, 0)))
        XCTAssertFalse(RingPlan.showDayStart(run: PersistedRun(input: run.input, ended: true), state: RingState(), now: at(3, 9, 0)))
        XCTAssertFalse(RingPlan.showDayStart(run: PersistedRun(input: run.input, pausedAt: at(2, 9, 0)), state: RingState(), now: at(3, 9, 0)))
    }

    // Story 2: a Ring day rings its sets; a Quiet day rings none.
    func testStory2_ringAndQuietDays() {
        var state = RingState()
        state.choose(.ring, on: date(2))
        XCTAssertEqual(RingPlan.ringing(alerts: alerts(day: 2, every: 60, count: 5), state: state, date: date(2)).count, 5)
        state.choose(.quiet, on: date(2))
        XCTAssertTrue(RingPlan.ringing(alerts: alerts(day: 2, every: 60, count: 5), state: state, date: date(2)).isEmpty)
    }

    // Story 2, open question 3: dense days ring at most every 30 minutes; the sets between are banners.
    func testStory2_denseDaysCapped() {
        let state = RingState()
        let day10 = RingPlan.ringing(alerts: alerts(day: 10, every: 15, count: 8), state: state, date: date(10))
        XCTAssertEqual(day10.map(\.index), [1, 3, 5, 7])
        let day9 = RingPlan.ringing(alerts: alerts(day: 9, every: 20, count: 7), state: state, date: date(9))
        XCTAssertEqual(day9.map(\.index), [1, 3, 5, 7])
        let day5 = RingPlan.ringing(alerts: alerts(day: 5, every: 30, count: 4), state: state, date: date(5))
        XCTAssertEqual(day5.count, 4)
    }

    // AlarmKit alarms are kept to a small queue, refilled like the alert queue.
    func testStory2_alarmQueueCapped() {
        let many = RingPlan.ringing(alerts: alerts(day: 2, every: 60, from: 6, count: 17), state: RingState(), date: date(2))
        XCTAssertEqual(many.count, RingPlan.alarmCapacity)
    }

    // Story 3 and 4: Quiet next mutes the next set, and sets stay quiet until an acknowledgment; then the next rings.
    func testStory3and4_quietUntilAcknowledged() {
        var state = RingState()
        let day = alerts(day: 2, every: 60, count: 6)
        state.quietNext(at: at(2, 8, 1))
        XCTAssertTrue(state.quietActive)
        XCTAssertTrue(RingPlan.ringing(alerts: day, state: state, date: date(2)).isEmpty)
        state.acknowledge(at: at(2, 10, 3))
        XCTAssertFalse(state.quietActive)
        XCTAssertFalse(RingPlan.ringing(alerts: day, state: state, date: date(2)).isEmpty)
    }

    // Story 4: an acknowledgment from before Quiet next doesn't end it; the next day's choice does.
    func testStory4_oldAcknowledgmentAndNewDay() {
        var state = RingState()
        state.acknowledge(at: at(2, 7, 30))
        state.quietNext(at: at(2, 8, 1))
        XCTAssertTrue(state.quietActive)
        state.choose(.ring, on: date(3))
        XCTAssertFalse(state.quietActive)
    }

    // Day-start copy encourages and never counts missed sets.
    func testDayStartCopy() {
        XCTAssertEqual(Copy.dayStart(day: 5, sets: 31), "Day 5.\n31 sets today.")
        XCTAssertEqual(Copy.morningAlarm(day: 5, sets: 1), "Day 5. 1 set today.")
        for line in [Copy.ringDetail, Copy.quietDetail, Copy.dayStart(day: 2, sets: 16)] {
            XCTAssertFalse(line.lowercased().contains("missed"), line)
            XCTAssertFalse(line.lowercased().contains("streak"), line)
            XCTAssertFalse(line.contains("!"), line)
        }
    }

    // The stored state round-trips and trims old days.
    func testStateStorage() throws {
        var state = RingState()
        state.choose(.quiet, on: date(1))
        state.choose(.ring, on: date(40))
        state.trim(before: date(40))
        XCTAssertNil(state.choice(on: date(1)))
        XCTAssertEqual(state.choice(on: date(40)), .ring)
        let again = try JSONDecoder().decode(RingState.self, from: JSONEncoder().encode(state))
        XCTAssertEqual(again, state)
    }
}
