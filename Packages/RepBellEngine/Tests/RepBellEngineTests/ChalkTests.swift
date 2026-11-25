import Foundation
import XCTest
@testable import RepBellEngine

/// Build C: one design system for every target (UX-19, UX-20), contrast (UX-17), spec values (UX-35).
final class ChalkTests: XCTestCase {
    private func tokensFile() throws -> [String: Any] {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()  // RepBellEngineTests
            .deletingLastPathComponent()  // Tests
            .deletingLastPathComponent()  // RepBellEngine
            .deletingLastPathComponent()  // Packages
            .deletingLastPathComponent()  // repo
            .appendingPathComponent("docs/design-system/tokens.json")
        let data = try Data(contentsOf: url)
        return try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    private func hex(_ value: String) -> ChalkTokens.RGB {
        ChalkTokens.RGB(Int(value.dropFirst(), radix: 16) ?? -1)
    }

    // UX-19, UX-20: the color tokens in code match tokens.json one to one.
    func testUX19_colorsMatchTokensFile() throws {
        let file = try tokensFile()
        let color = try XCTUnwrap(file["color"] as? [String: Any])
        let tokens = try XCTUnwrap(color["tokens"] as? [[String: String]])
        let code: [String: ChalkTokens.RGB] = [
            "ground": ChalkTokens.ground, "ground-watch": ChalkTokens.groundWatch, "surface": ChalkTokens.surface,
            "line": ChalkTokens.line, "line-strong": ChalkTokens.lineStrong, "ink": ChalkTokens.ink,
            "ink-muted": ChalkTokens.inkMuted, "ink-faint": ChalkTokens.inkFaint,
            "volt": ChalkTokens.volt, "on-volt": ChalkTokens.onVolt, "flood": ChalkTokens.flood, "flood-soft": ChalkTokens.floodSoft,
            "ultraviolet": ChalkTokens.ultraviolet, "alert": ChalkTokens.alert,
            "glow-violet": ChalkTokens.glowViolet, "glow-volt": ChalkTokens.glowVolt,
        ]
        XCTAssertEqual(tokens.count, code.count, "tokens.json and code list the same tokens")
        for (name, rgb) in code {
            let entry = try XCTUnwrap(tokens.first { $0["name"] == name }, name)
            XCTAssertEqual(hex(entry["value"] ?? ""), rgb, name)
        }
    }

    // UX-19, UX-35: spacing and radii match tokens.json.
    func testUX19_spacingAndRadiiMatchTokensFile() throws {
        let file = try tokensFile()
        func values(_ group: String) throws -> [String: Double] {
            let section = try XCTUnwrap(file[group] as? [String: Any])
            let tokens = try XCTUnwrap(section["tokens"] as? [[String: String]])
            return Dictionary(uniqueKeysWithValues: tokens.map { ($0["name"] ?? "", Double(($0["value"] ?? "").replacingOccurrences(of: "px", with: "")) ?? -1) })
        }
        let space = try values("spacing")
        XCTAssertEqual(space["space-1"], ChalkTokens.Space.s1)
        XCTAssertEqual(space["space-4"], ChalkTokens.Space.s4)
        XCTAssertEqual(space["space-6"], ChalkTokens.Space.s6)
        let radius = try values("radius")
        XCTAssertEqual(radius["radius-set"], ChalkTokens.Radius.set)
        XCTAssertEqual(radius["radius-button"], ChalkTokens.Radius.button)
        XCTAssertEqual(radius["radius-card"], ChalkTokens.Radius.card)
        XCTAssertEqual(radius["radius-panel"], ChalkTokens.Radius.panel)
    }

    // UX-17: text meets 4.5:1 and meaningful marks meet 3:1 on ground, in both contrast settings.
    func testUX17_contrast() {
        let ground = ChalkTokens.ground
        XCTAssertGreaterThanOrEqual(ChalkTokens.ink.contrast(with: ground), 4.5)
        XCTAssertGreaterThanOrEqual(ChalkTokens.inkMuted.contrast(with: ground), 4.5)
        XCTAssertGreaterThanOrEqual(ChalkTokens.volt.contrast(with: ground), 4.5)
        XCTAssertGreaterThanOrEqual(ChalkTokens.onVolt.contrast(with: ChalkTokens.volt), 4.5)
        // The bell-ring flood: volt number, ink and flood-soft text on the dark flood, which stays a dark tint.
        XCTAssertGreaterThanOrEqual(ChalkTokens.volt.contrast(with: ChalkTokens.flood), 4.5)
        XCTAssertGreaterThanOrEqual(ChalkTokens.ink.contrast(with: ChalkTokens.flood), 4.5)
        XCTAssertGreaterThanOrEqual(ChalkTokens.floodSoft.contrast(with: ChalkTokens.flood), 4.5)
        XCTAssertLessThan(ChalkTokens.flood.luminance, 0.05)
        XCTAssertGreaterThanOrEqual(ChalkTokens.onVolt.contrast(with: ChalkTokens.ultraviolet), 4.5)
        // Ultraviolet is large text only: 3:1 on ground and surface.
        XCTAssertGreaterThanOrEqual(ChalkTokens.ultraviolet.contrast(with: ground), 3.0)
        XCTAssertGreaterThanOrEqual(ChalkTokens.ultraviolet.contrast(with: ChalkTokens.surface), 3.0)
        XCTAssertGreaterThanOrEqual(ChalkTokens.markOutline.contrast(with: ground), 3.0)
        XCTAssertGreaterThanOrEqual(ChalkTokens.markOutlineHigh.contrast(with: ground), 3.0)
        XCTAssertGreaterThan(ChalkTokens.markOutlineHigh.contrast(with: ground), ChalkTokens.markOutline.contrast(with: ground))
    }

    // UX-17: VoiceOver hears the tally, not just "Today's sets".
    // The background glow keeps every text colour at 4.5:1 or better everywhere on the screen, on a small and a
    // large phone, and the violet day bars at 3:1 or better where they sit at the top.
    func testGlowKeepsContrast() {
        for (w, h) in [(375.0, 667.0), (440.0, 956.0)] {
            var worst = ChalkTokens.ground
            var worstTop = ChalkTokens.ground
            for xi in 0...40 {
                for yi in 0...80 {
                    let x = w * Double(xi) / 40, y = h * Double(yi) / 80
                    let c = ChalkTokens.Glow.color(x: x, y: y, width: w, height: h)
                    if c.luminance > worst.luminance { worst = c }
                    if y < 200, c.luminance > worstTop.luminance { worstTop = c }
                }
            }
            for text in [ChalkTokens.ink, ChalkTokens.inkMuted, ChalkTokens.volt] {
                XCTAssertGreaterThanOrEqual(text.contrast(with: worst), 4.5, "\(text) on \(worst)")
            }
            XCTAssertGreaterThanOrEqual(ChalkTokens.ultraviolet.contrast(with: worstTop), 3.0)
        }
    }

    func testUX17_spokenTally() {
        let marks: [Copy.SpokenMark] = [.done, .done, .done, .done, .missed, .current, .upcoming]
        XCTAssertEqual(Copy.tallySpoken(marks: marks), "4 done, 1 missed, set 6 next")
        XCTAssertEqual(Copy.tallySpoken(marks: [.done, .missed]), "1 done, 1 missed, no sets left")
    }

    // UX-35, UX-23: component values follow the spec.
    func testUX35_componentValues() {
        XCTAssertEqual(ChalkTokens.stepBarHeight, 6)
        XCTAssertEqual(ChalkTokens.choiceCardMinHeight, 76)
        XCTAssertEqual(ChalkTokens.Size.title, 28)
        XCTAssertEqual(ChalkTokens.Size.label, 15)
        XCTAssertEqual(ChalkTokens.minimumTarget, 44)
    }
}
