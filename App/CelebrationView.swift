import RepBellEngine
import SwiftUI
import UIKit

/// Full-screen "you did it" moment after logging a set in the app.
struct CelebrationView: View {
    var celebration: Celebration
    var dismiss: () -> Void

    @State private var shown = false
    @State private var ring = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// With Reduce Motion, nothing scales, rotates or slides: the moment only fades in.
    private func scale(_ from: CGFloat) -> CGFloat { reduceMotion || shown ? 1 : from }

    /// Amber means now (a set just done); ultraviolet means earned (the whole day done).
    private var tone: Color { celebration.dayComplete ? Chalk.ultraviolet : Chalk.amber }
    /// Day 15 floods the whole screen ultraviolet; everything on it is on-amber near-black (5.4:1).
    private var flood: Bool { celebration.finalTest }
    private var ground: Color { flood ? Chalk.ultraviolet : Chalk.ground }
    private var mark: Color { flood ? Chalk.onAmber : tone }
    private var markInk: Color { flood ? Chalk.ultraviolet : Chalk.onAmber }
    private var ink: Color { flood ? Chalk.onAmber : Chalk.ink }
    private var muted: Color { flood ? Chalk.onAmber : Chalk.inkMuted }
    private var title: String {
        flood ? Copy.finalTestDone : (celebration.dayComplete ? Copy.dayDone : Copy.didIt)
    }
    private var number: Int {
        flood ? celebration.reps : (celebration.dayComplete ? celebration.repsToday : celebration.reps)
    }
    private var line: String {
        if flood { return Copy.finalTestLine(start: celebration.startMax, end: celebration.reps, percent: celebration.percent) }
        return celebration.dayComplete
            ? Copy.dayDoneLine(day: celebration.day, repsToday: celebration.repsToday)
            : Copy.celebrationLine(done: celebration.done, total: celebration.total, repsToday: celebration.repsToday)
    }

    var body: some View {
        ZStack {
            ground.ignoresSafeArea()
            // At large text sizes the moment scrolls instead of cutting its line short.
            ViewThatFits(in: .vertical) {
                moment
                ScrollView { moment }
            }
        }
        .preferredColorScheme(flood ? .light : nil)
        .contentShape(Rectangle())
        .onTapGesture { dismiss() }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .onAppear {
            if reduceMotion {
                withAnimation(.easeOut(duration: 0.2)) { shown = true }
            } else {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.55)) { shown = true }
                // A finished day rings out more slowly.
                withAnimation(.easeOut(duration: celebration.dayComplete ? 1.6 : 0.9)) { ring = true }
            }
        }
        .task {
            #if DEBUG
            // Screenshot mode holds the celebration on screen for the capture.
            if ProgramController.screenshotState != nil { return }
            #endif
            // With VoiceOver on it waits for a tap, so it can be read in full.
            guard let seconds = CelebrationTiming.autoDismiss(dayComplete: celebration.dayComplete, voiceOverRunning: UIAccessibility.isVoiceOverRunning) else { return }
            try? await Task.sleep(for: .seconds(seconds))
            dismiss()
        }
    }

    private var moment: some View {
            VStack(spacing: 20) {
                Spacer()
                ZStack {
                    Circle()
                        .stroke(mark.opacity(ring || reduceMotion ? 0 : 0.6), lineWidth: 6)
                        .frame(width: celebration.dayComplete ? 280 : 220, height: celebration.dayComplete ? 280 : 220)
                        .scaleEffect(ring ? 1.6 : 0.8)
                    Circle()
                        .fill(mark)
                        .frame(width: celebration.dayComplete ? 230 : 180, height: celebration.dayComplete ? 230 : 180)
                        .scaleEffect(scale(0.2))
                    Image(systemName: "checkmark")
                        .font(.system(size: 88, weight: .black))
                        .accessibilityHidden(true)
                        .foregroundStyle(markInk)
                        .scaleEffect(scale(0.1))
                        .rotationEffect(.degrees(reduceMotion || shown ? 0 : -30))
                }
                Text(title)
                    .font(Chalk.display(64))
                    .lineLimit(1)
                    .minimumScaleFactor(0.4)
                    .multilineTextAlignment(.center)
                    .textCase(.uppercase)
                    .foregroundStyle(ink)
                    .opacity(shown ? 1 : 0)
                    .offset(y: reduceMotion || shown ? 0 : 24)
                // A finished day leads with the day's total; Day 15 with the new max.
                Text("\(number)")
                    .font(Chalk.display(120))
                    .lineLimit(1)
                    .minimumScaleFactor(0.4)
                    .foregroundStyle(flood ? Chalk.onAmber : tone)
                    .opacity(shown ? 1 : 0)
                    .scaleEffect(scale(0.6))
                Text(line)
                    .font(.body.weight(.medium))
                    .foregroundStyle(muted)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .opacity(shown ? 1 : 0)
                Spacer()
                Text(Copy.tapToContinue)
                    .font(.subheadline)
                    .foregroundStyle(muted)
            }
            .padding(24)
            .frame(maxWidth: .infinity)
    }
}
