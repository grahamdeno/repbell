import Foundation
import XCTest
@testable import RepBellEngine

/// Animated figures for Workouts and desk stretches (story of 22 Nov 2026).
final class FigureTests: XCTestCase {
    private var root: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
    }

    private func library() throws -> FigureLibrary {
        try FigureLibrary.decode(Data(contentsOf: root.appendingPathComponent("App/Studio/figures.json")))
    }

    private func movementIDs() throws -> [String] {
        let data = try Data(contentsOf: root.appendingPathComponent("App/Studio/movements.json"))
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let movements = try XCTUnwrap(json["movements"] as? [[String: Any]])
        return movements.compactMap { $0["id"] as? String }
    }

    // Every Workouts movement has an animated figure.
    func testEveryMovementHasAClip() throws {
        let lib = try library()
        let ids = try movementIDs()
        XCTAssertEqual(ids.count, 146)
        for id in ids { XCTAssertNotNil(lib.clips[id], id) }
    }

    // Every desk stretch has an animated figure.
    func testEveryDeskStretchHasAClip() throws {
        let lib = try library()
        for stretch in DeskStretch.all { XCTAssertNotNil(lib.clips[stretch.id], stretch.id) }
    }

    // Body clips carry every joint inside the drawing box; hand clips name their motion.
    func testClipsAreWellFormed() throws {
        let lib = try library()
        let views: Set<String> = ["side", "front", "hand"]
        for (id, clip) in lib.clips {
            XCTAssertTrue(views.contains(clip.view), id)
            XCTAssertGreaterThan(clip.cycle, 0, id)
            XCTAssertTrue(clip.frames.indices.contains(clip.still), id)
            if clip.view == "hand" {
                XCTAssertNotNil(clip.hand, id)
                continue
            }
            XCTAssertGreaterThanOrEqual(clip.frames.count, 2, id)
            for frame in clip.frames {
                for joint in FigureClip.bodyJoints { XCTAssertNotNil(frame[joint], "\(id) \(joint)") }
                for (joint, p) in frame {
                    XCTAssertTrue((-4...lib.box[0] + 4).contains(p[0]), "\(id) \(joint) x")
                    XCTAssertTrue((-4...lib.box[1] + 4).contains(p[1]), "\(id) \(joint) y")
                }
            }
        }
    }

    // The grip move is a hand close-up, since a line figure can't show fingers. The rice bucket moves are gone
    // (decision of 25 Nov 2026).
    func testGripMovesAreHandCloseUps() throws {
        let lib = try library()
        XCTAssertNil(lib.clips["rice-grab"])
        XCTAssertEqual(lib.clips["grip-squeeze"]?.hand, "squeeze")
        XCTAssertEqual(lib.clips["grip-squeeze"]?.bucket, false)
    }

    private func twoFrameClip(seconds: Double = 1, hold: Double = 0.5) -> FigureClip {
        let a: [String: [Double]] = ["hd": [0, 0], "ha": [10, 10]]
        let b: [String: [Double]] = ["hd": [20, 0], "ha": [30, 40]]
        return FigureClip(view: "side", frames: [a, b], seconds: seconds, hold: hold, floor: true, still: 1,
                          props: nil, arrows: nil, hand: nil, bucket: nil)
    }

    // Holds at the first position, eases to the second, holds, then eases back.
    func testTimingHoldsThenEases() {
        let clip = twoFrameClip()
        XCTAssertEqual(clip.cycle, 3, accuracy: 0.0001)
        XCTAssertEqual(clip.phase(at: 0.2).progress, 0, accuracy: 0.0001)
        XCTAssertEqual(clip.phase(at: 1.0).progress, 0.5, accuracy: 0.0001)
        XCTAssertEqual(clip.pose(at: 1.5)["hd"]?.x ?? -1, 20, accuracy: 0.0001)
        XCTAssertEqual(clip.pose(at: 1.8)["hd"]?.x ?? -1, 20, accuracy: 0.0001)
        XCTAssertEqual(clip.pose(at: 3.0)["hd"]?.x ?? -1, 0, accuracy: 0.0001)
        XCTAssertEqual(clip.pose(at: 3.2)["hd"]?.x ?? -1, 0, accuracy: 0.0001)
    }

    // Reduce Motion shows the still position and never moves.
    func testStillPoseIsTheTargetPosition() {
        let clip = twoFrameClip()
        XCTAssertEqual(clip.stillPose["ha"], FigurePoint(30, 40))
    }

    // Hand progress runs 0 to 1 and back.
    func testHandProgressGoesAndReturns() {
        let clip = twoFrameClip()
        XCTAssertEqual(clip.handProgress(at: 0.2), 0, accuracy: 0.0001)
        XCTAssertEqual(clip.handProgress(at: 1.6), 1, accuracy: 0.0001)
        XCTAssertEqual(clip.handProgress(at: 2.5), 0.5, accuracy: 0.0001)
    }
}
