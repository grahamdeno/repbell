import RepBellEngine
import SwiftUI

enum Chalk {
    static let ground = Color(red: 0x12 / 255, green: 0x12 / 255, blue: 0x12 / 255)
    static let groundWatch = Color.black
    static let surface = Color(red: 0x1A / 255, green: 0x1A / 255, blue: 0x19 / 255)
    static let line = Color(red: 0x2E / 255, green: 0x2D / 255, blue: 0x2A / 255)
    static let lineStrong = Color(red: 0x3A / 255, green: 0x39 / 255, blue: 0x36 / 255)
    static let ink = Color(red: 0xF2 / 255, green: 0xF0 / 255, blue: 0xEB / 255)
    static let inkSoft = Color(red: 0xC9 / 255, green: 0xC6 / 255, blue: 0xC0 / 255)
    static let inkMuted = Color(red: 0xA3 / 255, green: 0xA0 / 255, blue: 0x9A / 255)
    static let inkFaint = Color(red: 0x6E / 255, green: 0x6B / 255, blue: 0x66 / 255)
    static let accent = Color(red: 1, green: 0x6A / 255, blue: 0x13 / 255)
    static let accentPressed = Color(red: 1, green: 0x8A / 255, blue: 0x45 / 255)
    static let onAccent = Color(red: 0x12 / 255, green: 0x12 / 255, blue: 0x12 / 255)
    static let watchSecondary = Color(red: 0x26 / 255, green: 0x26 / 255, blue: 0x24 / 255)

    enum Display: Sendable {
        case bold, extraBold, black
    }

    static func display(_ size: CGFloat, weight: Display = .extraBold) -> Font {
        let name: String
        switch weight {
        case .bold: name = "BarlowCondensed-Bold"
        case .extraBold: name = "BarlowCondensed-ExtraBold"
        case .black: name = "BarlowCondensed-Black"
        }
        return .custom(name, size: size)
    }
}

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

struct ScreenChrome<Content: View>: View {
    var top: CGFloat = 8
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(.horizontal, 24)
            .padding(.top, top)
            .padding(.bottom, 24)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Chalk.ground.ignoresSafeArea())
    }
}

struct PrimaryButton: View {
    var title: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(Chalk.accent)
                .foregroundStyle(Chalk.onAccent)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}

struct SecondaryButton: View {
    var title: String
    var height: CGFloat = 60
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: height < 60 ? 16 : 18, weight: .semibold))
                .frame(maxWidth: .infinity)
                .frame(height: height)
                .foregroundStyle(Chalk.ink)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Chalk.lineStrong, lineWidth: 1.5))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}

struct StepBars: View {
    var filled: Int
    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<5, id: \.self) { index in
                Capsule()
                    .fill(index < filled ? Chalk.accent : Chalk.line)
                    .frame(height: 4)
            }
        }
        .accessibilityLabel("Step \(filled) of 5")
    }
}

struct DayBars: View {
    var marks: [DayBar]
    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(marks.enumerated()), id: \.offset) { _, mark in
                Capsule()
                    .fill(mark.color)
                    .frame(height: 6)
            }
        }
    }
}

enum DayBar {
    case past, today, future
    var color: Color {
        switch self {
        case .past: Chalk.ink
        case .today: Chalk.accent
        case .future: Chalk.line
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
                    .font(Chalk.display(30))
                    .textCase(.uppercase)
                    .foregroundStyle(recommended ? Chalk.onAccent : Chalk.ink)
                Text(detail)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(recommended ? Chalk.onAccent.opacity(0.8) : Chalk.inkMuted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .frame(minHeight: 88)
            .background(recommended ? Chalk.accent : Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(recommended ? Color.clear : Chalk.lineStrong, lineWidth: 1.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

struct TextLink: View {
    var title: String
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(Chalk.accent)
                .padding(12)
        }
        .buttonStyle(.plain)
    }
}
