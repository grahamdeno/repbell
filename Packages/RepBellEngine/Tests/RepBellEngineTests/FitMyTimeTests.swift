import XCTest
@testable import RepBellEngine

/// Fit my time: a session that lasts exactly the time chosen, shaped by the program day.
final class FitMyTimeTests: XCTestCase {
    private let pools = FitMyTime.Pools(
        warmUp: [.init(id: "march", eachSide: false), .init(id: "arm-circles", eachSide: false), .init(id: "hip-circles", eachSide: false), .init(id: "good-morning", eachSide: false)],
        main: [.init(id: "squat", eachSide: false), .init(id: "reverse-lunge", eachSide: true), .init(id: "glute-bridge", eachSide: false), .init(id: "superman", eachSide: false), .init(id: "split-squat", eachSide: true)],
        coolDown: [.init(id: "childs-pose", eachSide: false), .init(id: "wall-chest", eachSide: true), .init(id: "hamstring-fold", eachSide: false), .init(id: "breathing", eachSide: false)]
    )

    func testChoicesIncludeFiveMinutes() {
        XCTAssertEqual(FitMyTime.choices, [5, 10, 15, 20, 30, 45])
    }

    func testEveryChoiceEndsExactlyOnTime() {
        for minutes in FitMyTime.choices {
            for seed in 0..<5 {
                let steps = FitMyTime.build(minutes: minutes, pools: pools, seed: seed)
                XCTAssertEqual(steps.reduce(0) { $0 + $1.seconds }, minutes * 60, "\(minutes) min, seed \(seed)")
            }
        }
    }

    func testShapeWarmUpMainCoolDown() {
        let steps = FitMyTime.build(minutes: 15, pools: pools, seed: 1)
        XCTAssertEqual(steps.first?.type, "getReady")
        let moves = steps.compactMap(\.id)
        XCTAssertEqual(moves.first, "march")
        XCTAssertEqual(steps.last(where: { $0.type == "move" })?.id, "breathing")
        XCTAssertTrue(moves.contains("squat") || moves.contains("glute-bridge"))
        let allowed = Set((pools.warmUp + pools.main + pools.coolDown).map(\.id))
        XCTAssertTrue(Set(moves).isSubset(of: allowed))
    }

    func testFiveMinutesStillHasEveryPart() {
        let steps = FitMyTime.build(minutes: 5, pools: pools, seed: 2)
        let moves = steps.compactMap(\.id)
        XCTAssertTrue(moves.contains("march"))
        XCTAssertTrue(moves.contains { id in pools.main.contains { $0.id == id } })
        XCTAssertTrue(moves.contains("childs-pose"))
    }

    func testTwoSidedMovesSplitWithSwitch() {
        let steps = FitMyTime.build(minutes: 30, pools: pools, seed: 3)
        for (i, step) in steps.enumerated() where step.side == "left" {
            XCTAssertEqual(steps[i + 1].type, "switch")
            XCTAssertEqual(steps[i + 2].side, "right")
            XCTAssertEqual(steps[i + 2].id, step.id)
        }
    }

    func testAnotherOneChangesTheMix() {
        let orders = (0..<6).map { seed in FitMyTime.build(minutes: 20, pools: pools, seed: seed).compactMap(\.id) }
        XCTAssertGreaterThan(Set(orders.map { $0.joined(separator: ",") }).count, 1)
        XCTAssertEqual(FitMyTime.build(minutes: 20, pools: pools, seed: 4), FitMyTime.build(minutes: 20, pools: pools, seed: 4))
    }

    func testFocusFollowsTheProgramDay() {
        XCTAssertEqual(FitMyTime.focus(programDay: 1), .mobility)
        XCTAssertEqual(FitMyTime.focus(programDay: 9), .mobility)
        XCTAssertEqual(FitMyTime.focus(programDay: 4), .legs)
        XCTAssertEqual(FitMyTime.focus(programDay: 5), .core)
        XCTAssertEqual(FitMyTime.focus(programDay: nil), .fullBody)
    }

    // Left-over time is spread over the cool-down, so no single stretch runs long.
    func testLeftoverSpreadAcrossCoolDown() {
        for minutes in [30, 45] {
            let steps = FitMyTime.build(minutes: minutes, pools: pools, seed: 1)
            let breathing = steps.last { $0.id == "breathing" }!
            XCTAssertLessThanOrEqual(breathing.seconds, 90, "\(minutes) min")
        }
    }

    // The rest before the cool-down names the cool-down's first move.
    func testRestBeforeCoolDownNamesIt() {
        let steps = FitMyTime.build(minutes: 15, pools: pools, seed: 2)
        let firstCool = steps.firstIndex { $0.id == "childs-pose" }!
        XCTAssertEqual(steps[firstCool - 1].next, "childs-pose")
    }
}
