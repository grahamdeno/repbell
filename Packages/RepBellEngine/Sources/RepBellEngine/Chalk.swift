import Foundation
#if canImport(SwiftUI)
import SwiftUI
#endif

/// The Chalk design system, mapped one to one from docs/design-system/tokens.json.
///
/// The values live here, in the engine, so the iPhone app, the Watch app, the widget and the alarm share one
/// source. `ChalkTokens` holds plain numbers and is tested; `Chalk` turns them into SwiftUI colors and fonts.
public enum ChalkTokens {
    public struct RGB: Equatable, Sendable {
        public let red: Int
        public let green: Int
        public let blue: Int
        public init(_ hex: Int) {
            red = (hex >> 16) & 0xFF
            green = (hex >> 8) & 0xFF
            blue = hex & 0xFF
        }

        /// WCAG relative luminance.
        public var luminance: Double {
            func channel(_ value: Int) -> Double {
                let c = Double(value) / 255
                return c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
            }
            return 0.2126 * channel(red) + 0.7152 * channel(green) + 0.0722 * channel(blue)
        }

        /// WCAG contrast ratio against another color.
        public func contrast(with other: RGB) -> Double {
            let a = luminance, b = other.luminance
            return (max(a, b) + 0.05) / (min(a, b) + 0.05)
        }
    }

    public static let ground = RGB(0x121212)
    public static let groundWatch = RGB(0x000000)
    public static let surface = RGB(0x1A1A19)
    public static let line = RGB(0x2E2D2A)
    public static let lineStrong = RGB(0x3A3936)
    public static let ink = RGB(0xF2F0EB)
    public static let inkSoft = RGB(0xC9C6C0)
    public static let inkMuted = RGB(0xA3A09A)
    public static let inkFaint = RGB(0x6E6B66)
    public static let accent = RGB(0xFF6A13)
    public static let accentPressed = RGB(0xFF8A45)
    public static let onAccent = RGB(0x121212)
    public static let watchSecondary = RGB(0x262624)

    /// Outlines and bars that carry meaning (upcoming sets, future days). At least 3:1 on ground.
    public static let markOutline = inkFaint
    /// The same, when the person turns on Increase Contrast.
    public static let markOutlineHigh = inkMuted

    public enum Space {
        public static let s1: Double = 4
        public static let s2: Double = 8
        public static let s3: Double = 12
        public static let s4: Double = 16
        public static let s6: Double = 24
        public static let s8: Double = 32
        public static let s16: Double = 64
    }

    public enum Radius {
        public static let bar: Double = 3
        public static let set: Double = 6
        public static let button: Double = 14
        public static let card: Double = 16
        public static let panel: Double = 28
    }

    /// Point sizes at the default text size. Each grows with the person's text size.
    public enum Size {
        public static let hero: Double = 160
        public static let large: Double = 150
        public static let watchNumber: Double = 72
        public static let headline: Double = 48
        public static let title: Double = 28
        public static let eyebrow: Double = 22
        public static let button: Double = 18
        public static let body: Double = 17
        public static let label: Double = 15
        public static let caption: Double = 13
    }

    public static let minimumTarget: Double = 44
    public static let stepBarHeight: Double = 6
    public static let choiceCardMinHeight: Double = 76
}

#if canImport(SwiftUI)
@available(iOS 17.0, watchOS 10.0, macOS 14.0, *)
public enum Chalk {
    public static func color(_ rgb: ChalkTokens.RGB) -> Color {
        Color(red: Double(rgb.red) / 255, green: Double(rgb.green) / 255, blue: Double(rgb.blue) / 255)
    }

    public static var ground: Color { color(ChalkTokens.ground) }
    public static var groundWatch: Color { color(ChalkTokens.groundWatch) }
    public static var surface: Color { color(ChalkTokens.surface) }
    public static var line: Color { color(ChalkTokens.line) }
    public static var lineStrong: Color { color(ChalkTokens.lineStrong) }
    public static var ink: Color { color(ChalkTokens.ink) }
    public static var inkSoft: Color { color(ChalkTokens.inkSoft) }
    public static var inkMuted: Color { color(ChalkTokens.inkMuted) }
    public static var inkFaint: Color { color(ChalkTokens.inkFaint) }
    public static var accent: Color { color(ChalkTokens.accent) }
    public static var accentPressed: Color { color(ChalkTokens.accentPressed) }
    public static var onAccent: Color { color(ChalkTokens.onAccent) }
    public static var watchSecondary: Color { color(ChalkTokens.watchSecondary) }

    /// Outline for marks that carry meaning, stronger when Increase Contrast is on.
    public static func markOutline(_ contrast: ColorSchemeContrast) -> Color {
        color(contrast == .increased ? ChalkTokens.markOutlineHigh : ChalkTokens.markOutline)
    }

    public enum Display: Sendable {
        case bold, extraBold, black
    }

    /// Barlow Condensed at a size that grows with the person's text size.
    public static func display(_ size: CGFloat, weight: Display = .extraBold) -> Font {
        let name: String
        switch weight {
        case .bold: name = "BarlowCondensed-Bold"
        case .extraBold: name = "BarlowCondensed-ExtraBold"
        case .black: name = "BarlowCondensed-Black"
        }
        let style: Font.TextStyle
        if size >= 40 {
            style = .largeTitle
        } else if size >= 28 {
            style = .title
        } else if size >= 20 {
            style = .title3
        } else {
            style = .headline
        }
        return .custom(name, size: size, relativeTo: style)
    }

    /// The type scale. Display styles use Barlow Condensed; text styles use the system font. All grow with text size.
    public enum TypeScale {
        public static var hero: Font { Chalk.display(CGFloat(ChalkTokens.Size.hero)) }
        public static var large: Font { Chalk.display(CGFloat(ChalkTokens.Size.large)) }
        public static var headline: Font { Chalk.display(CGFloat(ChalkTokens.Size.headline)) }
        public static var title: Font { Chalk.display(CGFloat(ChalkTokens.Size.title), weight: .bold) }
        public static var eyebrow: Font { Chalk.display(CGFloat(ChalkTokens.Size.eyebrow), weight: .bold) }
        public static var button: Font { .headline }
        public static var body: Font { .body }
        public static var label: Font { .subheadline.weight(.medium) }
        public static var caption: Font { .footnote }
    }
}
#endif
