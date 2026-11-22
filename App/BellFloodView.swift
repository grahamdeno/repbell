import RepBellEngine
import SwiftUI

/// The bell-ring flood (design system: SetAlert). When a set is due and Today is open, the whole screen turns the
/// dark olive `flood`: the number leads in volt, and Done is the one primary action. A dark tint rather than a full
/// lime screen, so it reads from across the room without glare (22 Nov 2026). Reduce Motion shows it without animation.
struct BellFloodView: View {
    @Environment(ProgramController.self) private var controller
    var set: ScheduledSet
    var total: Int
    var showBusy: Bool

    var body: some View {
        ScreenChrome(background: Chalk.flood) {
            VStack(alignment: .leading, spacing: ChalkTokens.Space.s4) {
                HStack(alignment: .firstTextBaseline, spacing: ChalkTokens.Space.s2) {
                    Image(systemName: "bell.fill")
                        .font(.title3)
                        .foregroundStyle(Chalk.volt)
                        .accessibilityHidden(true)
                    Text(Copy.floodEyebrow(set: set.index, total: total, day: set.day))
                        .eyebrow()
                        .foregroundStyle(Chalk.floodSoft)
                }
                .padding(.top, ChalkTokens.Space.s6)
                Text("\(set.reps)")
                    .font(Chalk.display(200))
                    .lineLimit(1)
                    .minimumScaleFactor(0.3)
                    .foregroundStyle(Chalk.volt)
                Text(Copy.pushUpsNow)
                    .font(Chalk.display(28, weight: .bold))
                    .textCase(.uppercase)
                    .foregroundStyle(Chalk.floodSoft)
                Spacer(minLength: ChalkTokens.Space.s6)
                Button { controller.logDone(day: set.day, index: set.index, celebrate: true) } label: {
                    Text(Copy.doneSet(set.reps))
                        .font(Chalk.TypeScale.button)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, minHeight: 60)
                        .foregroundStyle(Chalk.onVolt)
                        .background(Chalk.volt, in: RoundedRectangle(cornerRadius: ChalkTokens.Radius.button))
                        .contentShape(Rectangle())
                }
                .buttonStyle(PressFade())
                Button { controller.logSnooze(day: set.day, index: set.index) } label: {
                    Text(Copy.inTen)
                        .font(Chalk.TypeScale.button)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, minHeight: 56)
                        .foregroundStyle(Chalk.ink)
                        .overlay(RoundedRectangle(cornerRadius: ChalkTokens.Radius.button).stroke(Chalk.floodSoft, lineWidth: 1.5))
                        .contentShape(Rectangle())
                }
                .buttonStyle(PressFade())
                if showBusy {
                    Button { controller.confirmBusy() } label: {
                        Text(Copy.busy)
                            .font(.subheadline.weight(.semibold))
                            .underline()
                            .foregroundStyle(Chalk.floodSoft)
                            .frame(maxWidth: .infinity, minHeight: ChalkTokens.minimumTarget)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PressFade())
                }
            }
        }
    }
}
