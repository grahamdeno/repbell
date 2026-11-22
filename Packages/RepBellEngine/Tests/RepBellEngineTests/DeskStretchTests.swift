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
}
