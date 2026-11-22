import RepBellEngine
import SwiftUI

struct CounterView: View {
    @Environment(ProgramController.self) private var controller
    var day: Int
    @State private var originCount: Int?
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var originY: CGFloat?

    var body: some View {
        // At accessibility sizes the page scrolls (the -1 and +1 buttons still set the count) and rows stack.
        let large = typeSize.isAccessibilitySize
        ScreenChrome(scrolls: large) {
            VStack(alignment: .leading, spacing: 16) {
                if large {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(Copy.testEyebrow(day: day))
                            .eyebrow()
                        Text(Copy.goodForm)
                            .font(.subheadline)
                            .foregroundStyle(Chalk.inkMuted)
                    }
                } else {
                    HStack {
                        Text(Copy.testEyebrow(day: day))
                            .eyebrow()
                        Spacer()
                        Text(Copy.goodForm)
                            .font(.subheadline)
                            .foregroundStyle(Chalk.inkMuted)
                    }
                }
                Text(Copy.counterPrompt)
                    .font(.body)
                    .foregroundStyle(Chalk.inkMuted)
                counter
                if large {
                    HStack(spacing: 12) {
                        SecondaryButton(title: "−1") { controller.adjustCount(by: -1) }
                            .accessibilityLabel("Subtract one")
                        SecondaryButton(title: "+1") { controller.adjustCount(by: 1) }
                            .accessibilityLabel("Add one")
                    }
                    PrimaryButton(title: Copy.done) { controller.showConfirm(day: day) }
                        .disabled(!TestFlow.canSubmit(count: controller.draftCount))
                } else {
                    HStack(spacing: 12) {
                        SecondaryButton(title: "−1") { controller.adjustCount(by: -1) }
                            .accessibilityLabel("Subtract one")
                        SecondaryButton(title: "+1") { controller.adjustCount(by: 1) }
                            .accessibilityLabel("Add one")
                        PrimaryButton(title: Copy.done) { controller.showConfirm(day: day) }
                            .disabled(!TestFlow.canSubmit(count: controller.draftCount))
                    }
                }
                TextLink(title: Copy.notYet) { controller.deferTest() }
                    .frame(maxWidth: .infinity)
                    .accessibilityHint(Copy.notYetDetail)
            }
        }
        .sensoryFeedback(.selection, trigger: controller.draftCount)
    }

    private var counter: some View {
        VStack(spacing: 6) {
            Image(systemName: "chevron.up")
                .font(.headline)
                .foregroundStyle(Chalk.inkFaint)
            Text("\(controller.draftCount + 1)")
                .font(Chalk.display(40, weight: .bold))
                .foregroundStyle(Chalk.inkFaint)
            Text("\(controller.draftCount)")
                .font(Chalk.display(160))
                .foregroundStyle(Chalk.amber)
                .lineLimit(1)
                .minimumScaleFactor(0.4)
            Text(controller.draftCount > 0 ? "\(controller.draftCount - 1)" : " ")
                .font(Chalk.display(40, weight: .bold))
                .foregroundStyle(Chalk.inkFaint)
            Image(systemName: "chevron.down")
                .font(.headline)
                .foregroundStyle(Chalk.inkFaint)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .trailing) {
            TickRuler(count: controller.draftCount)
                .padding(.trailing, 16)
        }
        .background(Chalk.surface)
        .overlay(RoundedRectangle(cornerRadius: 28).stroke(Chalk.line, lineWidth: 1.5))
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .contentShape(Rectangle())
        .gesture(drag)
        .accessibilityElement()
        .accessibilityLabel("Push-up count. Slide up to add, down to subtract.")
        .accessibilityValue("\(controller.draftCount)")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: controller.adjustCount(by: 1)
            case .decrement: controller.adjustCount(by: -1)
            default: break
            }
        }
    }

    private var drag: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if originCount == nil {
                    originCount = controller.draftCount
                    originY = value.startLocation.y
                }
                let startY = originY ?? value.startLocation.y
                let delta = CounterMath.reps(forDrag: Double(startY - value.location.y))
                controller.draftCount = min(500, max(0, (originCount ?? 0) + delta))
            }
            .onEnded { _ in
                originCount = nil
                originY = nil
            }
    }
}

private struct TickRuler: View {
    var count: Int
    var body: some View {
        VStack {
            ForEach(0..<15, id: \.self) { index in
                let major = (index + count) % 5 == 0
                let mid = index == 7
                Capsule()
                    .fill(mid ? Chalk.amber : (major ? Chalk.inkFaint : Chalk.lineStrong))
                    .frame(width: mid ? 20 : (major ? 14 : 8), height: 2)
                if index < 14 { Spacer(minLength: 0) }
            }
        }
        .padding(.vertical, 28)
        .frame(width: 28)
    }
}
