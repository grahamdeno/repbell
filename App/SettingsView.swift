import RepBellEngine
import SwiftUI

/// Everything you can change, in one place. Profile is for your numbers.
struct SettingsView: View {
    @Environment(ProgramController.self) private var controller
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase

    @State private var wake = Date()
    @State private var bed = Date()
    @State private var loaded = false
    @State private var savedNote: String?
    @State private var alertRows: [ProfileRow] = []
    @State private var testMessage: String?
    @State private var confirmStartOver = false
    @State private var restoring = false

    var body: some View {
        ScreenChrome(top: 28) {
            VStack(alignment: .leading, spacing: 0) {
                Text(Copy.settingsTitle)
                    .font(Chalk.display(48))
                    .textCase(.uppercase)
                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {
                        if controller.library.current != nil {
                            schedule
                        }
                        alerts
                        if StudioFeature.enabled {
                            StudioProfileSection()
                        }
                        if Features.payment {
                            purchase
                        }
                        ProfileSection(Copy.programSection) {
                            if let run = controller.library.current, !run.ended {
                                if run.pausedAt == nil {
                                    Text(Copy.pauseBody)
                                        .font(.system(size: 15))
                                        .foregroundStyle(Chalk.inkSoft)
                                    SecondaryButton(title: Copy.pauseTitle, height: 56) {
                                        controller.pause()
                                        controller.screen = .today
                                    }
                                } else {
                                    PrimaryButton(title: Copy.resume) {
                                        controller.resume()
                                        controller.screen = .today
                                    }
                                }
                            }
                            Text(Copy.startOverBody)
                                .font(.system(size: 15))
                                .foregroundStyle(Chalk.inkSoft)
                                .padding(.top, 8)
                            SecondaryButton(title: Copy.startOverTitle, height: 56) { confirmStartOver = true }
                        }
                        TextLink(title: Copy.aboutTitle) { controller.screen = .about }
                    }
                    .padding(.vertical, 16)
                }
                .scrollIndicators(.hidden)
                SecondaryButton(title: Copy.back) { controller.screen = .profile }
                    .padding(.top, 12)
            }
        }
        .onAppear(perform: loadTimes)
        .task { await loadAlertRows() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await loadAlertRows() } }
        }
        .confirmationDialog(Copy.startOverConfirmTitle, isPresented: $confirmStartOver, titleVisibility: .visible) {
            Button(Copy.startOverTitle, role: .destructive) { controller.startOver() }
            Button(Copy.back, role: .cancel) {}
        } message: {
            Text(Copy.startOverConfirmBody)
        }
    }

    // MARK: Schedule

    private var schedule: some View {
        let current = controller.currentWindow()
        let newWake = ClockTime(date: wake)
        let newBed = ClockTime(date: bed)
        let changed = current.map { $0.wake != newWake || $0.bed != newBed } ?? false
        let preview = changed ? controller.previewWindow(wake: newWake, bed: newBed) : nil
        return ProfileSection(Copy.scheduleTitle) {
            DatePicker(Copy.wakeLabel, selection: $wake, displayedComponents: .hourAndMinute)
                .foregroundStyle(Chalk.inkSoft)
                .tint(Chalk.accent)
            DatePicker(Copy.endOfDayLabel, selection: $bed, displayedComponents: .hourAndMinute)
                .foregroundStyle(Chalk.inkSoft)
                .tint(Chalk.accent)
            if let preview {
                Text(Copy.windowPreview(before: preview.before, after: preview.after, last: preview.last))
                    .font(.system(size: 15))
                    .foregroundStyle(Chalk.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
                PrimaryButton(title: Copy.saveTimes) {
                    controller.changeWindow(wake: newWake, bed: newBed)
                    savedNote = Copy.timesSaved
                    Haptics.play(.tap)
                }
            } else if let savedNote {
                Text(savedNote)
                    .font(.system(size: 14))
                    .foregroundStyle(Chalk.inkMuted)
            } else {
                Text(Copy.scheduleChangeNote)
                    .font(.system(size: 14))
                    .foregroundStyle(Chalk.inkMuted)
            }
        }
    }

    private func loadTimes() {
        guard !loaded, let window = controller.currentWindow() else { return }
        wake = window.wake.dateToday()
        bed = window.bed.dateToday()
        loaded = true
    }

    // MARK: Alerts

    private var alerts: some View {
        ProfileSection(Copy.alertsSection) {
            ProfileRows(items: alertRows)
            if alertRows.contains(where: { $0.value == "Off" || $0.value == "Not asked yet" || $0.value.hasPrefix("On (") }) {
                Text(Copy.alertsFixHint)
                    .font(.system(size: 14))
                    .foregroundStyle(Chalk.inkSoft)
                TextLink(title: Copy.openSettings) {
                    if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                        openURL(url)
                    }
                }
            }
            Text(Copy.alertsCheckBody)
                .font(.system(size: 14))
                .foregroundStyle(Chalk.inkMuted)
            SecondaryButton(title: Copy.sendTestAlert, height: 56) {
                Task {
                    let sent = await Notifier.sendTestAlert()
                    testMessage = sent ? Copy.testAlertSent : Copy.testAlertFailed
                    await loadAlertRows()
                }
            }
            if let testMessage {
                Text(testMessage)
                    .font(.system(size: 14))
                    .foregroundStyle(Chalk.inkMuted)
            }
        }
    }

    private func loadAlertRows() async {
        await controller.refreshAlerts()
        alertRows = await Notifier.diagnostics()
    }

    // MARK: Purchase

    private var purchase: some View {
        ProfileSection(Copy.unlockSection) {
            ProfileRowView(item: ProfileRow(label: "Status", value: controller.library.unlocked ? Copy.unlocked : Copy.notUnlocked))
            if !controller.library.unlocked {
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
    }
}

extension ClockTime {
    init(date: Date) {
        let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
        self.init(hour: parts.hour ?? 0, minute: parts.minute ?? 0)
    }

    func dateToday() -> Date {
        Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
    }
}
