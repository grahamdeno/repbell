import RepBellEngine
import SwiftUI

struct ProfileView: View {
    @Environment(ProgramController.self) private var controller
    @State private var confirmStartOver = false
    @State private var restoring = false

    var body: some View {
        let model = controller.profileSnapshot()
        ScreenChrome(top: 28) {
            VStack(alignment: .leading, spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {
                        Text(Copy.profileTitle)
                            .font(Chalk.display(48))
                            .textCase(.uppercase)
                        if !model.run.isEmpty {
                            section(Copy.thisRun) { rows(model.run) }
                        }
                        section(Copy.yourRecord) {
                            if model.record.isEmpty {
                                Text(Copy.recordEmpty)
                                    .font(.system(size: 15))
                                    .foregroundStyle(Chalk.inkMuted)
                            } else {
                                rows(model.record)
                            }
                        }
                        if !model.schedule.isEmpty {
                            section(Copy.scheduleTitle) {
                                rows(model.schedule)
                                Text(Copy.scheduleNote)
                                    .font(.system(size: 14))
                                    .foregroundStyle(Chalk.inkMuted)
                            }
                        }
                        section(Copy.unlockSection) {
                            row(ProfileRow(label: "Status", value: model.unlocked ? Copy.unlocked : Copy.notUnlocked))
                            if !model.unlocked {
                                TextLink(title: Copy.restorePurchase) {
                                    guard !restoring else { return }
                                    restoring = true
                                    Task {
                                        await controller.restorePurchases()
                                        restoring = false
                                    }
                                }
                                if let message = controller.unlockMessage {
                                    Text(message)
                                        .font(.system(size: 14))
                                        .foregroundStyle(Chalk.inkMuted)
                                }
                            }
                        }
                        section(Copy.startOverTitle) {
                            Text(Copy.startOverBody)
                                .font(.system(size: 15))
                                .foregroundStyle(Chalk.inkSoft)
                            SecondaryButton(title: Copy.startOverTitle, height: 56) { confirmStartOver = true }
                        }
                        TextLink(title: Copy.aboutTitle) { controller.screen = .about }
                    }
                    .padding(.bottom, 16)
                }
                .scrollIndicators(.hidden)
                SecondaryButton(title: Copy.back) {
                    controller.screen = controller.library.current == nil ? .promise : .today
                }
                .padding(.top, 12)
            }
        }
        .confirmationDialog(Copy.startOverConfirmTitle, isPresented: $confirmStartOver, titleVisibility: .visible) {
            Button(Copy.startOverTitle, role: .destructive) { controller.startOver() }
            Button(Copy.back, role: .cancel) {}
        } message: {
            Text(Copy.startOverConfirmBody)
        }
    }

    @ViewBuilder
    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(Chalk.display(22, weight: .bold))
                .tracking(0.8)
                .textCase(.uppercase)
                .foregroundStyle(Chalk.inkMuted)
            content()
        }
    }

    @ViewBuilder
    private func rows(_ items: [ProfileRow]) -> some View {
        VStack(spacing: 0) {
            ForEach(items) { item in
                row(item)
            }
        }
    }

    private func row(_ item: ProfileRow) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(item.label)
                .font(.system(size: 16))
                .foregroundStyle(Chalk.inkSoft)
            Spacer(minLength: 12)
            Text(item.value)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Chalk.ink)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 12)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Chalk.line).frame(height: 1)
        }
        .accessibilityElement(children: .combine)
    }
}

struct BusySheet: View {
    @Environment(ProgramController.self) private var controller

    var body: some View {
        let skipped = controller.setsInNextHour()
        let resume = Copy.clock(controller.busyUntil())
        VStack(alignment: .leading, spacing: 16) {
            Text(Copy.busySheetTitle)
                .font(Chalk.display(34))
                .textCase(.uppercase)
                .foregroundStyle(Chalk.ink)
            if skipped.isEmpty {
                Text(Copy.busyNothingSkipped(resume: resume))
                    .font(.system(size: 16))
                    .foregroundStyle(Chalk.inkSoft)
            } else {
                Text(Copy.busySkipIntro(count: skipped.count))
                    .font(.system(size: 16))
                    .foregroundStyle(Chalk.inkSoft)
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(skipped) { set in
                        Text(Copy.skippedRow(time: set.alert.map { Copy.clock($0) } ?? "", reps: set.reps))
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Chalk.ink)
                    }
                }
                Text(Copy.busyResume(resume))
                    .font(.system(size: 15))
                    .foregroundStyle(Chalk.inkMuted)
            }
            Spacer(minLength: 8)
            PrimaryButton(title: Copy.busyPause) { controller.confirmBusy() }
            SecondaryButton(title: Copy.back, height: 56) { controller.showBusyConfirm = false }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Chalk.ground.ignoresSafeArea())
        .presentationDetents([.medium, .large])
        .presentationBackground(Chalk.ground)
    }
}
