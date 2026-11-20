import RepBellEngine
import SwiftUI

// Colors, fonts and the type scale live in the engine (`Chalk`, `ChalkTokens`) so every target shares them.

struct Chevron: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.30, y: rect.minY + rect.height * 0.30))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.minY + rect.height * 0.16))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.70, y: rect.minY + rect.height * 0.30))
        return path
    }
}

struct Wordmark: View {
    var mark: CGFloat = 30
    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Chalk.surface
                Chevron()
                    .stroke(Chalk.accent, style: StrokeStyle(lineWidth: mark * 0.16, lineCap: .round, lineJoin: .round))
                    .padding(mark * 0.08)
                Text("14")
                    .font(Chalk.display(mark * 0.62, weight: .black))
                    .foregroundStyle(Chalk.ink)
                    .offset(y: mark * 0.16)
            }
            .frame(width: mark, height: mark)
            .clipShape(RoundedRectangle(cornerRadius: mark * 0.22))
            Text(Copy.wordmark)
                .font(Chalk.display(26))
                .tracking(2)
                .textCase(.uppercase)
                .foregroundStyle(Chalk.ink)
        }
    }
}

/// The frame every iPhone screen sits in. When the content doesn't fit (large text, small phone), it scrolls.
/// Screens that already scroll, or that use a vertical drag, pass `scrolls: false`.
/// The content is built for both the fitting and the scrolling layout, so a child's `@State` resets if the
/// screen switches between them (for example when text size changes). Keep screen state in the controller.
struct ScreenChrome<Content: View>: View {
    var top: CGFloat = 8
    var scrolls: Bool = true
    @ViewBuilder var content: () -> Content

    var body: some View {
        Group {
            if scrolls {
                ViewThatFits(in: .vertical) {
                    framed
                    ScrollView {
                        framed
                    }
                    .scrollIndicators(.hidden)
                }
            } else {
                framed
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Chalk.ground.ignoresSafeArea())
    }

    private var framed: some View {
        content()
            .padding(.horizontal, ChalkTokens.Space.s6)
            .padding(.top, top)
            .padding(.bottom, ChalkTokens.Space.s6)
            .frame(maxWidth: .infinity, alignment: .top)
    }
}

/// Primary action: accent fill, lighter when pressed, faded when disabled.
struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Chalk.TypeScale.button)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 60)
            .padding(.horizontal, ChalkTokens.Space.s4)
            .background(configuration.isPressed ? Chalk.accentPressed : Chalk.accent)
            .foregroundStyle(Chalk.onAccent)
            .clipShape(RoundedRectangle(cornerRadius: ChalkTokens.Radius.button))
            .opacity(isEnabled ? 1 : 0.4)
            .contentShape(Rectangle())
    }
}

/// Secondary action: outlined, filled with surface when pressed.
struct SecondaryButtonStyle: ButtonStyle {
    enum Size { case regular, compact }
    var size: Size = .regular

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(size == .regular ? Chalk.TypeScale.button : Font.body.weight(.semibold))
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .frame(minHeight: size == .regular ? 60 : 52)
            .padding(.horizontal, ChalkTokens.Space.s4)
            .foregroundStyle(Chalk.ink)
            .background(configuration.isPressed ? Chalk.surface : Color.clear)
            .overlay(RoundedRectangle(cornerRadius: ChalkTokens.Radius.button).stroke(Chalk.lineStrong, lineWidth: 1.5))
            .clipShape(RoundedRectangle(cornerRadius: ChalkTokens.Radius.button))
            .contentShape(Rectangle())
    }
}

struct PrimaryButton: View {
    var title: String
    var action: () -> Void

    var body: some View {
        Button(title, action: action)
            .buttonStyle(PrimaryButtonStyle())
    }
}

struct SecondaryButton: View {
    var title: String
    var size: SecondaryButtonStyle.Size = .regular
    var action: () -> Void

    init(title: String, size: SecondaryButtonStyle.Size = .regular, action: @escaping () -> Void) {
        self.title = title
        self.size = size
        self.action = action
    }

    /// Older call sites pass a height; anything under 60 points is the compact size.
    init(title: String, height: CGFloat, action: @escaping () -> Void) {
        self.init(title: title, size: height < 60 ? .compact : .regular, action: action)
    }

    var body: some View {
        Button(title, action: action)
            .buttonStyle(SecondaryButtonStyle(size: size))
    }
}

/// Uppercase display label above a section or screen.
struct Eyebrow: ViewModifier {
    var color: Color = Chalk.ink
    func body(content: Content) -> some View {
        content
            .font(Chalk.TypeScale.eyebrow)
            .tracking(0.8)
            .textCase(.uppercase)
            .foregroundStyle(color)
            .accessibilityAddTraits(.isHeader)
    }
}

extension View {
    func eyebrow(_ color: Color = Chalk.ink) -> some View { modifier(Eyebrow(color: color)) }

    /// The outlined card used for option rows and strips.
    func outlinedCard(radius: Double = ChalkTokens.Radius.card, color: Color = Chalk.lineStrong) -> some View {
        overlay(RoundedRectangle(cornerRadius: radius).stroke(color, lineWidth: 1.5))
    }
}

struct StepBars: View {
    var filled: Int
    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<5, id: \.self) { index in
                Capsule()
                    .fill(index < filled ? Chalk.accent : Chalk.line)
                    .frame(height: ChalkTokens.stepBarHeight)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Step \(filled) of 5")
    }
}

struct DayBars: View {
    var marks: [DayBar]
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        HStack(alignment: .center, spacing: ChalkTokens.Space.s1) {
            ForEach(Array(marks.enumerated()), id: \.offset) { _, mark in
                Capsule()
                    .fill(mark.color(contrast))
                    // Today is taller, so it never relies on color alone.
                    .frame(height: mark == .today ? 12 : 6)
            }
        }
        .frame(height: 12)
    }
}

enum DayBar: Equatable {
    case past, today, future
    func color(_ contrast: ColorSchemeContrast) -> Color {
        switch self {
        case .past: Chalk.ink
        case .today: Chalk.accent
        case .future: Chalk.markOutline(contrast)
        }
    }
}

struct ChoiceCard: View {
    var title: String
    var detail: String
    var recommended: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(Chalk.TypeScale.title)
                    .textCase(.uppercase)
                    .foregroundStyle(recommended ? Chalk.onAccent : Chalk.ink)
                Text(detail)
                    .font(Chalk.TypeScale.label)
                    .foregroundStyle(recommended ? Chalk.onAccent.opacity(0.8) : Chalk.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.vertical, ChalkTokens.Space.s4)
            .frame(minHeight: ChalkTokens.choiceCardMinHeight)
            .background(recommended ? Chalk.accent : Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: ChalkTokens.Radius.card)
                    .stroke(recommended ? Color.clear : Chalk.lineStrong, lineWidth: 1.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: ChalkTokens.Radius.card))
            .contentShape(Rectangle())
        }
        .buttonStyle(PressFade())
    }
}

/// A light pressed state for custom tappable rows.
struct PressFade: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.opacity(configuration.isPressed ? 0.7 : 1)
    }
}

struct TextLink: View {
    var title: String
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(Chalk.accent)
                .padding(.horizontal, ChalkTokens.Space.s3)
                .frame(minWidth: ChalkTokens.minimumTarget, minHeight: ChalkTokens.minimumTarget)
                .contentShape(Rectangle())
        }
        .buttonStyle(PressFade())
    }
}
