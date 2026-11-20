import RepBellEngine
import SwiftUI

/// Full-screen "you did it" moment after logging a set in the app.
struct CelebrationView: View {
    var celebration: Celebration
    var dismiss: () -> Void

    @State private var shown = false
    @State private var ring = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// With Reduce Motion, nothing scales, rotates or slides: the moment only fades in.
    private func scale(_ from: CGFloat) -> CGFloat { reduceMotion || shown ? 1 : from }

    var body: some View {
        ZStack {
            Chalk.ground.ignoresSafeArea()
            VStack(spacing: 20) {
                Spacer()
                ZStack {
                    Circle()
                        .stroke(Chalk.accent.opacity(ring || reduceMotion ? 0 : 0.6), lineWidth: 6)
                        .frame(width: 220, height: 220)
                        .scaleEffect(ring ? 1.6 : 0.8)
                    Circle()
                        .fill(Chalk.accent)
                        .frame(width: 180, height: 180)
                        .scaleEffect(scale(0.2))
                    Image(systemName: "checkmark")
                        .font(.system(size: 88, weight: .black))
                        .accessibilityHidden(true)
                        .foregroundStyle(Chalk.onAccent)
                        .scaleEffect(scale(0.1))
                        .rotationEffect(.degrees(reduceMotion || shown ? 0 : -30))
                }
                Text(celebration.dayComplete ? Copy.dayDone : Copy.didIt)
                    .font(Chalk.display(64))
                    .textCase(.uppercase)
                    .foregroundStyle(Chalk.ink)
                    .opacity(shown ? 1 : 0)
                    .offset(y: reduceMotion || shown ? 0 : 24)
                Text("\(celebration.reps)")
                    .font(Chalk.display(120))
                    .foregroundStyle(Chalk.accent)
                    .opacity(shown ? 1 : 0)
                    .scaleEffect(scale(0.6))
                Text(celebration.dayComplete
                     ? Copy.dayDoneLine(day: celebration.day, repsToday: celebration.repsToday)
                     : Copy.celebrationLine(done: celebration.done, total: celebration.total, repsToday: celebration.repsToday))
                    .font(.body.weight(.medium))
                    .foregroundStyle(Chalk.inkSoft)
                    .multilineTextAlignment(.center)
                    .opacity(shown ? 1 : 0)
                Spacer()
                Text(Copy.tapToContinue)
                    .font(.subheadline)
                    .foregroundStyle(Chalk.inkMuted)
            }
            .padding(24)
        }
        .contentShape(Rectangle())
        .onTapGesture { dismiss() }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .onAppear {
            if reduceMotion {
                withAnimation(.easeOut(duration: 0.2)) { shown = true }
            } else {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.55)) { shown = true }
                withAnimation(.easeOut(duration: 0.9)) { ring = true }
            }
        }
        .task {
            try? await Task.sleep(for: .seconds(celebration.dayComplete ? 3.5 : 2.5))
            dismiss()
        }
    }
}
