import RepBellEngine
import SwiftUI

struct HurtsView: View {
    @Environment(ProgramController.self) private var controller

    var body: some View {
        let day = controller.library.current?.input.dayNumber(on: CivilDateTime.local(Date()).date) ?? 1
        ScreenChrome(top: 28) {
            VStack(alignment: .leading, spacing: 20) {
                Text(Copy.hurtsHeadline)
                    .font(Chalk.display(52))
                    .textCase(.uppercase)
                    .foregroundStyle(Chalk.ink)
                Text(Copy.hurtsBody)
                    .font(.system(size: 17))
                    .foregroundStyle(Chalk.inkSoft)
                    .lineSpacing(4)
                Spacer(minLength: 16)
                option(title: Copy.pauseTitle, detail: Copy.pauseDetail(day: day)) { controller.pause() }
                option(title: Copy.endTitle, detail: Copy.endDetail) { controller.endProgram() }
                TextLink(title: Copy.back) { controller.screen = .today }
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private func option(title: String, detail: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Chalk.ink)
                Text(detail)
                    .font(.system(size: 14))
                    .foregroundStyle(Chalk.inkMuted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .frame(minHeight: 76)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Chalk.lineStrong, lineWidth: 1.5))
        }
        .buttonStyle(.plain)
    }
}

struct AboutView: View {
    @Environment(ProgramController.self) private var controller

    var body: some View {
        ScreenChrome(top: 28) {
            VStack(alignment: .leading, spacing: 20) {
                Text(Copy.aboutTitle)
                    .font(Chalk.display(48))
                    .textCase(.uppercase)
                Text(Copy.aboutBody)
                    .font(.system(size: 17))
                    .foregroundStyle(Chalk.inkSoft)
                    .lineSpacing(4)
                Spacer()
                SecondaryButton(title: Copy.back) {
                    controller.screen = controller.library.current == nil ? .promise : .profile
                }
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
                    .font(.system(size: 17))
                    .foregroundStyle(Chalk.inkSoft)
                    .lineSpacing(4)
                if let message = controller.unlockMessage {
                    Text(message)
                        .font(.system(size: 15))
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
