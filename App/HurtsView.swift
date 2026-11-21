import RepBellEngine
import SwiftUI

struct HurtsView: View {
    @Environment(ProgramController.self) private var controller
    @State private var confirmEnd = false

    var body: some View {
        let day = controller.library.current?.input.dayNumber(on: CivilDateTime.local(Date()).date) ?? 1
        ScreenChrome(top: 28) {
            VStack(alignment: .leading, spacing: 20) {
                Text(Copy.hurtsHeadline)
                    .font(Chalk.display(52))
                    .textCase(.uppercase)
                    .foregroundStyle(Chalk.ink)
                Text(Copy.hurtsBody)
                    .font(.body)
                    .foregroundStyle(Chalk.inkMuted)
                    .lineSpacing(4)
                Spacer(minLength: 16)
                ChoiceCard(title: Copy.pauseTitle, detail: Copy.pauseDetail(day: day), recommended: false) { controller.pause() }
                ChoiceCard(title: Copy.endTitle, detail: Copy.endDetail, recommended: false) { confirmEnd = true }
                TextLink(title: Copy.back) { controller.screen = .today }
                    .frame(maxWidth: .infinity)
            }
        }
        .confirmationDialog(Copy.endConfirmTitle, isPresented: $confirmEnd, titleVisibility: .visible) {
            Button(Copy.endConfirmButton, role: .destructive) { controller.endProgram() }
            Button(Copy.back, role: .cancel) {}
        } message: {
            Text(Copy.endConfirmBody)
        }
    }
}

struct AboutView: View {
    var body: some View {
        ScreenChrome(top: 8) {
            VStack(alignment: .leading, spacing: 20) {
                Text(Copy.aboutTitle)
                    .font(Chalk.display(48))
                    .textCase(.uppercase)
                Text(Copy.aboutBody)
                    .font(.body)
                    .foregroundStyle(Chalk.inkMuted)
                    .lineSpacing(4)
            }
        }
    }
}

struct PaywallView: View {
    @Environment(ProgramController.self) private var controller

    var body: some View {
        ScreenChrome(top: 28) {
            VStack(alignment: .leading, spacing: 20) {
                Text(Copy.unlockTitle)
                    .font(Chalk.display(48))
                    .textCase(.uppercase)
                Text(Copy.unlockBody)
                    .font(.body)
                    .foregroundStyle(Chalk.inkMuted)
                    .lineSpacing(4)
                if let message = controller.unlockMessage {
                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(Chalk.inkMuted)
                }
                Spacer()
                PrimaryButton(title: Copy.unlockButton) {
                    Task { await controller.purchaseUnlock() }
                }
            }
        }
    }
}
