import XCTest
@testable import RepBellEngine

/// Desk stretch: one stretch for sitting posture after a set, at most once an hour, off by default.
final class DeskStretchTests: XCTestCase {
    private let day = CivilDate(year: 2026, month: 11, day: 20)
    private func at(_ hour: Int, _ minute: Int) -> CivilDateTime { CivilDateTime(date: day, hour: hour, minute: minute) }

    func testOffDoesNothing() {
        XCTAssertFalse(DeskStretch.isDue(enabled: false, lastShown: nil, now: at(9, 0)))
    }

    func testAtMostOnceAnHour() {
        XCTAssertTrue(DeskStretch.isDue(enabled: true, lastShown: nil, now: at(9, 0)))
        XCTAssertFalse(DeskStretch.isDue(enabled: true, lastShown: at(9, 0), now: at(9, 45)))
        XCTAssertTrue(DeskStretch.isDue(enabled: true, lastShown: at(9, 0), now: at(10, 0)))
        XCTAssertTrue(DeskStretch.isDue(enabled: true, lastShown: CivilDateTime(date: day.addingDays(-1), hour: 22, minute: 0), now: at(7, 0)))
    }

    private struct TestRandom: RandomNumberGenerator {
        var state: UInt64
        mutating func next() -> UInt64 {
            state = state &* 6364136223846793005 &+ 1442695040888963407
            return state
        }
    }

    // A broad mix: every stretch comes up once before any repeats, and never the same one twice in a row.
    func testShuffledBagCoversEveryStretchWithoutBackToBackRepeats() {
        for seed in 1...20 {
            var random = TestRandom(state: UInt64(seed))
            var bag: [Int] = []
            var last: Int?
            var shown: [Int] = []
            for _ in 0..<(DeskStretch.all.count * 3) {
                let next = DeskStretch.next(bag: bag, last: last, using: &random)
                XCTAssertNotEqual(next.index, last, "seed \(seed)")
                shown.append(next.index)
                bag = next.bag
                last = next.index
            }
            for round in 0..<3 {
                let slice = shown[(round * DeskStretch.all.count)..<((round + 1) * DeskStretch.all.count)]
                XCTAssertEqual(Set(slice).count, DeskStretch.all.count, "seed \(seed) round \(round)")
            }
        }
    }

    // Two different starting points give different orders, so it isn't one fixed rotation.
    func testOrderIsShuffled() {
        var a = TestRandom(state: 1), b = TestRandom(state: 2)
        let first = DeskStretch.next(bag: [], last: nil, using: &a).bag
        let second = DeskStretch.next(bag: [], last: nil, using: &b).bag
        XCTAssertNotEqual(first, second)
    }

    // The names and cues match the Workouts movements they come from.
    func testStretchesMatchWorkoutsMovements() throws {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("App/Studio/movements.json")
        let root = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any])
        let movements = try XCTUnwrap(root["movements"] as? [[String: Any]])
        let byID = Dictionary(uniqueKeysWithValues: movements.compactMap { m in (m["id"] as? String).map { ($0, m) } })
        for stretch in DeskStretch.all {
            let movement = try XCTUnwrap(byID[stretch.id], stretch.id)
            XCTAssertEqual(movement["name"] as? String, stretch.name, stretch.id)
            XCTAssertEqual(movement["cues"] as? [String], stretch.cues, stretch.id)
            XCTAssertEqual((movement["sides"] as? String) == "each", stretch.eachSide, stretch.id)
        }
    }

    func testThirtySecondsAndSideNotes() {
        XCTAssertEqual(DeskStretch.seconds, 30)
        let hip = DeskStretch.all.first { $0.id == "hip-flexor" }!
        XCTAssertEqual(DeskStretch.sideNote(hip), "20 seconds on each side.")
        let doorway = DeskStretch.all.first { $0.id == "doorway-chest" }!
        XCTAssertNil(DeskStretch.sideNote(doorway))
    }

    func testStretchesTargetSittingAndCopyIsPlain() {
        XCTAssertGreaterThanOrEqual(DeskStretch.all.count, 15)
        XCTAssertEqual(Set(DeskStretch.all.map(\.id)).count, DeskStretch.all.count)
        for stretch in DeskStretch.all {
            XCTAssertEqual(stretch.cues.count, 2, stretch.id)
            for line in stretch.cues + [stretch.name] {
                XCTAssertFalse(line.contains("!"), line)
            }
        }
    }

    // Nothing counts until Start; then a get-ready, and each side held on its own with a switch between.
    func testPhasesStartWithGetReadyAndSplitSides() {
        let hip = DeskStretch.all.first { $0.id == "hip-flexor" }!
        XCTAssertEqual(DeskStretch.phases(hip).map(\.kind), [.getInPosition, .hold(side: "left"), .switchSides, .hold(side: "right")])
        XCTAssertEqual(DeskStretch.phases(hip).map(\.seconds), [5, 20, 5, 20])
        let doorway = DeskStretch.all.first { $0.id == "doorway-chest" }!
        XCTAssertEqual(DeskStretch.phases(doorway).map(\.kind), [.getInPosition, .hold(side: nil)])
        XCTAssertEqual(DeskStretch.phases(doorway).last?.seconds, 30)
    }

    // MARK: Item 20, hourly on weekdays

    private func at(_ y: Int, _ m: Int, _ d: Int, _ h: Int, _ min: Int = 0) -> CivilDateTime {
        CivilDateTime(date: CivilDate(year: y, month: m, day: d), hour: h, minute: min)
    }

    func testWeekdaysAreMondayToFriday() {
        // 23 Nov 2026 is a Monday.
        let days = (0..<7).map { DeskStretch.isWeekday(CivilDate(year: 2026, month: 11, day: 23).addingDays($0)) }
        XCTAssertEqual(days, [true, true, true, true, true, false, false])
    }

    func testDefaultWindowIsNineToFiveOnTheHour() {
        // Wednesday 25 Nov 2026, 8:30 a.m.
        let slots = DeskStretch.hourlySlots(after: at(2026, 11, 25, 8, 30), start: DeskStretch.defaultStartHour,
                                            end: DeskStretch.defaultEndHour, setAlerts: [], lastDone: nil, limit: 20, daysAhead: 0)
        XCTAssertEqual(slots.map { $0.minutes / 60 }, Array(9...17))
        XCTAssertTrue(slots.allSatisfy { $0.minutes % 60 == 0 })
    }

    func testNoRemindersAtTheWeekend() {
        // Friday 27 Nov, 6 p.m.: the next ones are Monday.
        let slots = DeskStretch.hourlySlots(after: at(2026, 11, 27, 18), start: 9, end: 17, setAlerts: [], lastDone: nil, limit: 3)
        XCTAssertEqual(slots.first, at(2026, 11, 30, 9))
        XCTAssertTrue(slots.allSatisfy { DeskStretch.isWeekday($0.date) })
    }

    func testAnHourWithASetNearItLeavesTheStretchToThatSet() {
        let now = at(2026, 11, 25, 8, 30)
        let bells = [at(2026, 11, 25, 10, 15), at(2026, 11, 25, 11, 50), at(2026, 11, 25, 13, 30), at(2026, 11, 25, 15, 31)]
        let hours = DeskStretch.hourlySlots(after: now, start: 9, end: 16, setAlerts: bells, lastDone: nil, limit: 20, daysAhead: 0)
            .map { $0.minutes / 60 }
        // 10:00, 12:00, 13:00 and 14:00 each have a bell within 30 minutes; 16:00 is 29 minutes from 15:31.
        // 9, 11 and 15 have none (15:00 is 31 minutes before 15:31), so they keep their reminder on the hour.
        XCTAssertEqual(hours, [9, 11, 15])
    }

    func testAProgramWithSetsAllDayLeavesEveryStretchToTheSets() {
        // Sets every 45 minutes from 7 a.m.: every hour mark has a bell within 30 minutes.
        let bells = (0..<20).map { CivilDateTime(date: CivilDate(year: 2026, month: 11, day: 25), minutes: 420 + $0 * 45) }
        let slots = DeskStretch.hourlySlots(after: at(2026, 11, 25, 6), start: 9, end: 17, setAlerts: bells, lastDone: nil,
                                            limit: 20, daysAhead: 0)
        XCTAssertEqual(slots, [])
    }

    func testSkipsTheHourAfterAStretch() {
        let hours = DeskStretch.hourlySlots(after: at(2026, 11, 25, 9, 40), start: 9, end: 12, setAlerts: [],
                                            lastDone: at(2026, 11, 25, 9, 40), limit: 20, daysAhead: 0).map { $0.minutes / 60 }
        XCTAssertEqual(hours, [11, 12])
    }

    func testTheWindowCanMove() {
        let hours = DeskStretch.hourlySlots(after: at(2026, 11, 25, 6), start: 7, end: 10, setAlerts: [], lastDone: nil,
                                            limit: 20, daysAhead: 0).map { $0.minutes / 60 }
        XCTAssertEqual(hours, [7, 8, 9, 10])
        XCTAssertEqual(DeskStretch.window(start: 15, end: 9).end, 15)
        XCTAssertEqual(DeskStretch.window(start: 2, end: 30).start, DeskStretch.windowHours.lowerBound)
        XCTAssertEqual(DeskStretch.window(start: 2, end: 30).end, DeskStretch.windowHours.upperBound)
    }

    func testRemindersShareTheSlotsWithSetAlerts() {
        // A program day with a full queue: 60 set alerts every 15 minutes from 7 a.m. Wednesday.
        let sets = (0..<60).map { CivilDateTime(date: CivilDate(year: 2026, month: 11, day: 25), minutes: 420 + $0 * 15) }
        let reminders = [at(2026, 11, 25, 9, 30), at(2026, 11, 25, 10, 30), at(2026, 11, 26, 9), at(2026, 11, 26, 10)]
        let shared = DeskStretch.sharedSlots(setAlerts: sets, reminders: reminders)
        XCTAssertEqual(shared.sets + shared.reminders, DeskStretch.systemNotificationLimit - 4 - 1)
        // Today's reminders are sooner than the last set alerts, so they go out; tomorrow's wait for a refill.
        XCTAssertEqual(shared.reminders, 2)
        XCTAssertEqual(shared.sets, 57)
        // With no reminders, the set alerts keep their 60.
        XCTAssertEqual(DeskStretch.sharedSlots(setAlerts: sets, reminders: []).sets, 60)
        // A quiet day: every reminder fits, up to the limit.
        let many = (9...17).map { at(2026, 11, 25, $0) } + (9...17).map { at(2026, 11, 26, $0) }
        XCTAssertEqual(DeskStretch.sharedSlots(setAlerts: [], reminders: many).reminders, DeskStretch.hourlyLimit)
        for count in stride(from: 0, through: 60, by: 5) {
            let s = DeskStretch.sharedSlots(setAlerts: Array(sets.prefix(count)), reminders: many)
            XCTAssertLessThanOrEqual(s.sets + s.reminders + 4 + 1, DeskStretch.systemNotificationLimit)
        }
        let limited = DeskStretch.hourlySlots(after: at(2026, 11, 25, 8), start: 9, end: 17, setAlerts: [], lastDone: nil, limit: 4)
        XCTAssertEqual(limited.count, 4)
    }

    func testRemindersNeverRepeatBackToBackAndCoverEveryStretch() {
        let now = at(2026, 11, 23, 8)
        // Bells every so often make gaps of different sizes.
        let bells = (0..<40).map { at(2026, 11, 23, 9).date.addingDays($0 / 8) }.enumerated().map { offset, date in
            CivilDateTime(date: date, hour: 9 + (offset * 3) % 9, minute: 5)
        }
        let slots = DeskStretch.hourlySlots(after: now, start: 9, end: 17, setAlerts: bells, lastDone: nil, limit: 200, daysAhead: 13)
        let indices = DeskStretch.stretchIndices(for: slots, previous: DeskStretch.stretchIndex(for: slots[0]))
        XCTAssertNotEqual(indices.first, DeskStretch.stretchIndex(for: slots[0]))
        XCTAssertTrue(zip(indices, indices.dropFirst()).allSatisfy { $0 != $1 })
        XCTAssertEqual(Set(indices).count, DeskStretch.all.count)
        XCTAssertEqual(DeskStretch.all.count, 19)
    }

    func testAReminderFindsItsStretch() {
        XCTAssertEqual(DeskStretch.stretch(id: "neck-stretch")?.name, "Neck side stretch")
        XCTAssertNil(DeskStretch.stretch(id: "rice-grab"))
    }

}
