import Foundation
#if canImport(SwiftUI)
import SwiftUI
#endif

/// The Volt design system (decision D7, 21 Nov 2026; formerly Chalk), mapped one to one from docs/design-system/tokens.json.
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

    public static let volt = RGB(0xC8FF00)
    public static let onVolt = RGB(0x0D0D0D)
    public static let flood = RGB(0x202B06)
    public static let floodSoft = RGB(0xA8C25A)
    public static let ultraviolet = RGB(0xA066FF)
    public static let ground = RGB(0x0D0D0D)
    public static let groundWatch = RGB(0x000000)
    public static let surface = RGB(0x1A1A1A)
    public static let line = RGB(0x2A2A2A)
    public static let lineStrong = RGB(0x3A3A3A)
    public static let ink = RGB(0xF2F2F2)
    public static let inkMuted = RGB(0xA0A0A0)
    public static let inkFaint = RGB(0x6E6B66)
    public static let alert = RGB(0xFF3B30)
    /// The background glow (decision of 25 Nov 2026): violet behind the top, volt from the bottom right,
    /// both laid over `ground` on every iPhone screen. The Watch stays black.
    public static let glowViolet = RGB(0x7846C8)
    public static let glowVolt = RGB(0x96CD00)

    public enum Glow {
        public struct Spot: Sendable {
            /// Centre as a fraction of the screen's width and height; radius as a fraction of its width.
            public let x: Double, y: Double, radius: Double, strength: Double
            public let color: RGB
        }
        public static let violet = Spot(x: -0.05, y: -0.02, radius: 1.15, strength: 0.30, color: glowViolet)
        public static let volt = Spot(x: 1.05, y: 1.02, radius: 1.25, strength: 0.25, color: glowVolt)
        public static let spots = [violet, volt]

        /// How strongly a spot shows at distance `t` (0 at its centre, 1 at its radius): strength × (1 − t)².
        public static func opacity(_ spot: Spot, at t: Double) -> Double {
            let k = max(0, 1 - t)
            return spot.strength * k * k
        }

        /// The background colour at a point, for contrast checks. Mirrors what the app draws.
        public static func color(x: Double, y: Double, width: Double, height: Double) -> RGB {
            var r = Double(ground.red), g = Double(ground.green), b = Double(ground.blue)
            for spot in spots {
                let dx = (x - spot.x * width) / (spot.radius * width)
                let dy = (y - spot.y * height) / (spot.radius * width)
                let a = opacity(spot, at: (dx * dx + dy * dy).squareRoot())
                r = r * (1 - a) + Double(spot.color.red) * a
                g = g * (1 - a) + Double(spot.color.green) * a
                b = b * (1 - a) + Double(spot.color.blue) * a
            }
            return RGB(Int(r.rounded()) << 16 | Int(g.rounded()) << 8 | Int(b.rounded()))
        }
    }
    /// Watch-only fill for secondary buttons. Not a design-system token.
    public static let watchSecondary = RGB(0x262626)

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

    public static var volt: Color { color(ChalkTokens.volt) }
    public static var onVolt: Color { color(ChalkTokens.onVolt) }
    public static var flood: Color { color(ChalkTokens.flood) }
    public static var floodSoft: Color { color(ChalkTokens.floodSoft) }
    public static var ultraviolet: Color { color(ChalkTokens.ultraviolet) }
    public static var ground: Color { color(ChalkTokens.ground) }
    public static var groundWatch: Color { color(ChalkTokens.groundWatch) }
    public static var surface: Color { color(ChalkTokens.surface) }
    public static var line: Color { color(ChalkTokens.line) }
    public static var lineStrong: Color { color(ChalkTokens.lineStrong) }
    public static var ink: Color { color(ChalkTokens.ink) }
    public static var inkMuted: Color { color(ChalkTokens.inkMuted) }
    public static var inkFaint: Color { color(ChalkTokens.inkFaint) }
    public static var alert: Color { color(ChalkTokens.alert) }
    public static var watchSecondary: Color { color(ChalkTokens.watchSecondary) }
    public static var glowViolet: Color { color(ChalkTokens.glowViolet) }
    public static var glowVolt: Color { color(ChalkTokens.glowVolt) }

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
