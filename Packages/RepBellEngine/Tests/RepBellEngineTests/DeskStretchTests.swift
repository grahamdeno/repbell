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

    func testRotationCoversEveryStretchThenRepeats() {
        var index: Int?
        var seen: [String] = []
        for _ in 0..<DeskStretch.all.count {
            let next = DeskStretch.next(after: index)
            seen.append(next.stretch.id)
            index = next.index
        }
        XCTAssertEqual(Set(seen).count, DeskStretch.all.count)
        XCTAssertEqual(DeskStretch.next(after: index).stretch.id, seen.first)
    }

    func testThirtySecondsAndSideNotes() {
        XCTAssertEqual(DeskStretch.seconds, 30)
        let hip = DeskStretch.all.first { $0.id == "hip-flexor" }!
        XCTAssertEqual(DeskStretch.sideNote(hip), "20 seconds on each side.")
        let doorway = DeskStretch.all.first { $0.id == "doorway-chest" }!
        XCTAssertNil(DeskStretch.sideNote(doorway))
    }

    func testStretchesTargetSittingAndCopyIsPlain() {
        XCTAssertEqual(Set(DeskStretch.all.map(\.id)), ["hip-flexor", "doorway-chest", "neck-stretch", "wall-chest", "seated-hamstring"])
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
