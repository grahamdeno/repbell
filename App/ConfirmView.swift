import RepBellEngine
import SwiftUI

struct ConfirmView: View {
    @Environment(ProgramController.self) private var controller
    var day: Int
    var reps: Int

    var body: some View {
        ScreenChrome(top: 28) {
            VStack(alignment: .leading, spacing: 20) {
                Text(Copy.yourMaxLine(reps))
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Chalk.inkMuted)
                Text("\(reps)")
                    .font(Chalk.display(160))
                    .foregroundStyle(Chalk.accent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.3)
                if let preview = controller.confirmPreview(day: day, reps: reps) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(Copy.todayPlan(reps: preview.reps, intervalMinutes: preview.intervalMinutes))
                            .font(Chalk.display(34, weight: .bold))
                            .textCase(.uppercase)
                            .foregroundStyle(Chalk.ink)
                        if let first = preview.sets.first?.grid, let last = preview.sets.last?.grid, !preview.sets.isEmpty {
                            Text(Copy.confirmDetail(first: first, last: last, count: preview.sets.count))
                                .font(.system(size: 16))
                                .foregroundStyle(Chalk.inkSoft)
                        } else {
                            Text(Copy.noSetsLeft(reps: preview.reps, intervalMinutes: preview.intervalMinutes))
                                .font(.system(size: 16))
                                .foregroundStyle(Chalk.inkSoft)
                        }
                    }
                    .padding(.top, 8)
                    .overlay(alignment: .top) {
                        Rectangle().fill(Chalk.line).frame(height: 1.5)
                    }
                }
                Spacer(minLength: 16)
                PrimaryButton(title: Copy.startTheDay) {
                    controller.commitTest(day: day, reps: reps)
                }
                TextLink(title: Copy.recount) {
                    controller.openCounter(day: day, preserve: true)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}
