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
                if Features.coachMedia {
                    Text(Copy.coachCredit)
                        .font(.body)
                        .foregroundStyle(Chalk.inkMuted)
                }
            }
        }
    }
}

/// What the unlock adds, the store's price, Buy, Restore purchase and a way out (roadmap item 18).
/// Shown as a sheet from Workouts and Coach voice; the program never shows it.
struct PaywallView: View {
    @Environment(ProgramController.self) private var controller
    @Environment(\.dismiss) private var dismiss
    @Environment(\.isPresented) private var isPresented
    @State private var price: String?
    @State private var working = false

    var body: some View {
        ScreenChrome(top: 28) {
            VStack(alignment: .leading, spacing: 20) {
                Text(Copy.unlockTitle)
                    .font(Chalk.display(48))
                    .textCase(.uppercase)
                    .accessibilityAddTraits(.isHeader)
                VStack(alignment: .leading, spacing: 12) {
                    Text(Copy.unlockWorkouts)
                    Text(Copy.unlockCoach)
                }
                .font(.body)
                .foregroundStyle(Chalk.ink)
                .fixedSize(horizontal: false, vertical: true)
                Text(Copy.unlockBody)
                    .font(.body)
                    .foregroundStyle(Chalk.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)
                if let message = controller.unlockMessage {
                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(Chalk.inkMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 8)
                PrimaryButton(title: price.map(Copy.unlockButton(price:)) ?? Copy.unlockButton) {
                    guard !working else { return }
                    working = true
                    Task {
                        if await controller.purchaseUnlock() { close() }
                        working = false
                    }
                }
                .disabled(working)
                SecondaryButton(title: Copy.restorePurchase, size: .compact) {
                    guard !working else { return }
                    working = true
                    Task {
                        await controller.restorePurchases()
                        if controller.library.unlocked { close() }
                        working = false
                    }
                }
                .disabled(working)
                TextLink(title: Copy.notNow) { close() }
                    .frame(maxWidth: .infinity)
            }
        }
        .task {
            controller.unlockMessage = nil
            price = await Unlocker.price()
        }
        .onChange(of: controller.unlockMessage) { _, message in
            if let message { AccessibilityNotification.Announcement(message).post() }
        }
    }

    /// As a sheet, closes the sheet. As a flow screen (screenshot mode only), goes back to Today or setup.
    private func close() {
        if isPresented {
            dismiss()
        } else {
            controller.screen = controller.library.current == nil ? .promise : .today
        }
    }
}
