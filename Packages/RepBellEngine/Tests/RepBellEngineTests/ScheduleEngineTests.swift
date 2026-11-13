import XCTest
@testable import RepBellEngine

/// The 13 cases from the Schedule engine spec, in order.
final class ScheduleEngineTests: XCTestCase {
    private let start = CivilDate(year: 2026, month: 11, day: 16)
    private let wake = ClockTime(hour: 7, minute: 0)
    private let bed = ClockTime(hour: 23, minute: 0)

    private func input(
        max: Int = 50,
        wake: ClockTime? = nil,
        bed: ClockTime? = nil,
        retest: Bool = true,
        events: [LogEvent] = []
    ) -> RunInput {
        RunInput(
            dayOneMax: max,
            wake: wake ?? self.wake,
            bed: bed ?? self.bed,
            start: start,
            retestEnabled: retest,
            events: events
        )
    }

    private func at(day: Int, _ hour: Int, _ minute: Int) -> CivilDateTime {
        CivilDateTime(date: start.addingDays(day - 1), hour: hour, minute: minute)
    }

    private func resolved(_ input: RunInput, day: Int, _ hour: Int, _ minute: Int) -> ResolvedRun {
        ScheduleEngine.resolve(input, now: at(day: day, hour, minute))
    }

    func test01_day1AfterTestLoggedAt705() {
        let run = resolved(
            input(events: [.test(day: 1, reps: 50, at: at(day: 1, 7, 5))]),
            day: 1, 7, 5
        )
        let day = run.day(1)!
        XCTAssertEqual(day.sets.count, 14)
        XCTAssertEqual(day.reps, 15)
        XCTAssertTrue(day.sets.allSatisfy { $0.reps == 15 })
        XCTAssertEqual(day.sets.first?.grid, at(day: 1, 8, 5))
        XCTAssertEqual(day.sets.last?.grid, at(day: 1, 21, 5))
        let minutes = day.sets.map(\.grid.minutes)
        XCTAssertEqual(minutes, (0..<14).map { (8 * 60 + 5) + $0 * 60 })
    }

    func test02_day4RoundsUp() {
        let run = resolved(input(max: 10), day: 4, 7, 0)
        XCTAssertEqual(run.day(4)?.reps, 3)
        XCTAssertEqual(RepsMath.count(max: 10, relativeIntensityPercent: 25), 3)
    }

    func test03_day9AvoidsFloatingPoint() {
        let run = resolved(input(max: 100, retest: false), day: 9, 7, 0)
        let reps = run.day(9)!.reps
        XCTAssertEqual(reps, 55)
        XCTAssertNotEqual(reps, 56)
    }

    func test04_day10Has61SetsEndingAt10pm() {
        let run = resolved(input(), day: 10, 6, 0)
        let day = run.day(10)!
        XCTAssertEqual(day.sets.count, 61)
        XCTAssertEqual(day.sets.first?.grid, at(day: 10, 7, 0))
        XCTAssertEqual(day.sets.last?.grid, at(day: 10, 22, 0))
        XCTAssertEqual(day.intervalMinutes, 15)
    }

    func test05_day14Has8SetsEndingAt9pm() {
        let run = resolved(input(), day: 14, 7, 0)
        let day = run.day(14)!
        XCTAssertEqual(day.sets.count, 8)
        XCTAssertEqual(day.sets.first?.grid, at(day: 14, 7, 0))
        XCTAssertEqual(day.sets.last?.grid, at(day: 14, 21, 0))
    }

    func test06_day9UsesDay8RetestEvenWhenHigher() {
        let run = resolved(
            input(events: [.test(day: 8, reps: 62, at: at(day: 8, 7, 5))]),
            day: 9, 7, 0
        )
        XCTAssertEqual(run.day(9)?.maxUsed, 62)
        XCTAssertEqual(run.day(9)?.reps, 35)
        XCTAssertFalse(run.day(9)!.usedDayOneMax)
    }

    func test07_day9KeepsDay1MaxWhenRetestOff() {
        let run = resolved(
            input(
                retest: false,
                events: [.test(day: 8, reps: 62, at: at(day: 8, 7, 5))]
            ),
            day: 9, 7, 0
        )
        XCTAssertEqual(run.day(9)?.maxUsed, 50)
        XCTAssertEqual(run.day(9)?.reps, 28)
        XCTAssertTrue(run.day(9)!.usedDayOneMax)
    }

    func test08_in10MinMovesOnlyThatSet() {
        let ten = at(day: 10, 10, 0)
        let run = resolved(
            input(events: [.snooze(day: 10, index: indexAt10am, at: ten)]),
            day: 10, 10, 0
        )
        let moved = run.day(10)!.set(indexAt10am)!
        let neighbor = run.day(10)!.set(indexAt10am + 1)!
        XCTAssertEqual(moved.alert, at(day: 10, 10, 10))
        XCTAssertEqual(moved.status, .upcoming)
        XCTAssertEqual(neighbor.grid, at(day: 10, 10, 15))
        XCTAssertEqual(neighbor.alert, at(day: 10, 10, 15))
    }

    func test09_secondIn10MinReachesTheNextSetAndMisses() {
        let first = at(day: 10, 10, 0)
        let second = at(day: 10, 10, 10)
        let run = resolved(
            input(events: [
                .snooze(day: 10, index: indexAt10am, at: first),
                .snooze(day: 10, index: indexAt10am, at: second)
            ]),
            day: 10, 10, 10
        )
        let moved = run.day(10)!.set(indexAt10am)!
        let neighbor = run.day(10)!.set(indexAt10am + 1)!
        XCTAssertEqual(moved.status, .missed)
        XCTAssertNil(moved.alert)
        XCTAssertEqual(neighbor.alert, at(day: 10, 10, 15))
        XCTAssertEqual(neighbor.status, .upcoming)
    }

    func test10_busyHourMissesTheSetInsideIt() {
        let run = resolved(
            input(events: [.busy(at: at(day: 2, 13, 20))]),
            day: 2, 13, 20
        )
        let two = run.day(2)!.sets.first { $0.grid == at(day: 2, 14, 0) }!
        let three = run.day(2)!.sets.first { $0.grid == at(day: 2, 15, 0) }!
        XCTAssertEqual(two.status, .missed)
        XCTAssertNil(two.alert)
        XCTAssertEqual(three.status, .upcoming)
        XCTAssertEqual(three.alert, at(day: 2, 15, 0))
    }

    func test11_shorterWindowOnDay2() {
        let run = resolved(
            input(wake: ClockTime(hour: 5, minute: 30), bed: ClockTime(hour: 21, minute: 0)),
            day: 2, 5, 30
        )
        let day = run.day(2)!
        XCTAssertEqual(day.sets.count, 15)
        XCTAssertEqual(day.sets.first?.grid, at(day: 2, 5, 30))
        XCTAssertEqual(day.sets.last?.grid, at(day: 2, 19, 30))
    }

    func test12_day8NotLoggedByNoonUsesDay1MaxAndStartsAtNoon() {
        let run = resolved(input(), day: 8, 12, 0)
        let day8 = run.day(8)!
        XCTAssertTrue(day8.usedDayOneMax)
        XCTAssertTrue(day8.setsStartAtNoon)
        XCTAssertEqual(day8.maxUsed, 50)
        XCTAssertEqual(day8.sets.first?.grid, at(day: 8, 12, 0))
        let day9 = run.day(9)!
        XCTAssertEqual(day9.maxUsed, 50)
        XCTAssertTrue(day9.usedDayOneMax)
        XCTAssertEqual(day9.sets.first?.grid, at(day: 9, 7, 0))
        XCTAssertTrue((9...14).allSatisfy { run.day($0)?.maxUsed == 50 })
    }

    func test13_day10QueueHolds60AndRefillAdds10pm() {
        let run = resolved(input(), day: 10, 6, 59)
        let early = run.alertQueue(at: at(day: 10, 6, 59))
        XCTAssertEqual(early.pending.count, 60)
        XCTAssertEqual(early.pending.first?.at, at(day: 10, 7, 0))
        XCTAssertEqual(early.pending.last?.at, at(day: 10, 21, 45))
        XCTAssertFalse(early.pending.contains { $0.at == at(day: 10, 22, 0) })
        XCTAssertEqual(early.waitingForRefill.first?.at, at(day: 10, 22, 0))

        // The 7:00 alert has fired, so the first refill takes the 10:00 p.m. set into the 60.
        let refilled = run.alertQueue(at: at(day: 10, 7, 0))
        XCTAssertEqual(refilled.pending.count, 60)
        XCTAssertTrue(refilled.pending.contains { $0.at == at(day: 10, 22, 0) })
        XCTAssertFalse(refilled.waitingForRefill.contains { $0.at == at(day: 10, 22, 0) })
    }

    /// 7:00 a.m. plus 12 steps of 15 minutes.
    private var indexAt10am: Int { 13 }
}
