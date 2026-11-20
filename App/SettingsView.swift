import RepBellEngine
import SwiftUI

/// Program settings: your day, alerts, the program, and About. Workouts settings live in Workouts.
struct SettingsView: View {
    @Environment(ProgramController.self) private var controller
    @Environment(\.scenePhase) private var scenePhase

    @State private var wake = ClockTime(hour: 7)
    @State private var bed = ClockTime(hour: 23)
    @State private var loaded = false
    @State private var savedNote: String?
    @State private var alertsOK = true
    @State private var testMessage: String?
    @State private var confirmStartOver = false

    var body: some View {
        ScreenChrome(top: 8, scrolls: false) {
            VStack(alignment: .leading, spacing: 0) {
                Text(Copy.settingsTitle)
                    .font(Chalk.display(48))
                    .textCase(.uppercase)
                    .accessibilityAddTraits(.isHeader)
                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {
                        if let run = controller.library.current, !run.ended {
                            schedule
                        }
                        alerts
                        program
                        ProfileSection(Copy.aboutTitle) {
                            SettingsRow(title: Copy.aboutTitle) { controller.open(.about) }
                        }
                    }
                    .padding(.vertical, 16)
                }
                .scrollIndicators(.hidden)
            }
        }
        .onAppear(perform: loadTimes)
        .task { await checkAlerts() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await checkAlerts() } }
        }
        .confirmationDialog(Copy.startOverConfirmTitle, isPresented: $confirmStartOver, titleVisibility: .visible) {
            Button(Copy.startOverTitle, role: .destructive) { controller.startOver() }
            Button(Copy.back, role: .cancel) {}
        } message: {
            Text(Copy.startOverConfirmBody)
        }
    }

    // MARK: Your day

    private var schedule: some View {
        let current = controller.currentWindow()
        let changed = current.map { $0.wake != wake || $0.bed != bed } ?? false
        let preview = changed ? controller.previewWindow(wake: wake, bed: bed) : nil
        return ProfileSection(Copy.scheduleTitle) {
            TimeChoiceRow(label: Copy.wakeLabel, choices: controller.wakeChoices(), selection: $wake)
            TimeChoiceRow(label: Copy.bedtimeLabel, choices: controller.bedChoices(), selection: $bed)
            Text(controller.lastSetLabel(wake: wake, bed: bed))
                .font(.subheadline)
                .foregroundStyle(Chalk.inkMuted)
            if let preview {
                Text(Copy.windowPreview(before: preview.before, after: preview.after, last: preview.last))
                    .font(.subheadline)
                    .foregroundStyle(Chalk.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
                PrimaryButton(title: Copy.saveTimes) {
                    controller.changeWindow(wake: wake, bed: bed)
                    savedNote = Copy.timesSaved
                    Haptics.play(.tap)
                }
            } else {
                Text(savedNote ?? Copy.scheduleChangeNote)
                    .font(.footnote)
                    .foregroundStyle(Chalk.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func loadTimes() {
        guard !loaded, let window = controller.currentWindow() else { return }
        wake = window.wake
        bed = window.bed
        loaded = true
    }

    // MARK: Alerts

    private var alerts: some View {
        ProfileSection(Copy.alertsSection) {
            ProfileRowView(item: ProfileRow(label: Copy.setAlertsTitle, value: alertsOK ? Copy.alertsOn : Copy.alertsNeedAttention))
            Text(Copy.testAlertHint)
                .font(.footnote)
                .foregroundStyle(Chalk.inkMuted)
                .fixedSize(horizontal: false, vertical: true)
            SecondaryButton(title: Copy.sendTestAlert, size: .compact) {
                Task {
                    let sent = await Notifier.sendTestAlert()
                    testMessage = sent ? Copy.testAlertSent : Copy.testAlertFailed
                    await checkAlerts()
                }
            }
            if let testMessage {
                Text(testMessage)
                    .font(.footnote)
                    .foregroundStyle(Chalk.inkMuted)
            }
            SettingsRow(title: Copy.alertsCheckTitle) { controller.open(.alertsCheck) }
        }
    }

    private func checkAlerts() async {
        await controller.refreshAlerts()
        let rows = await Notifier.diagnostics()
        alertsOK = !rows.contains(where: AlertsCheckView.needsAttention)
    }

    // MARK: Program

    private var program: some View {
        ProfileSection(Copy.programSection) {
            if let run = controller.library.current, !run.ended {
                if run.pausedAt == nil {
                    Text(Copy.pauseBody)
                        .font(.subheadline)
                        .foregroundStyle(Chalk.inkSoft)
                    SecondaryButton(title: Copy.pauseTitle, size: .compact) {
                        controller.pause()
                    }
                } else {
                    PrimaryButton(title: Copy.resume) {
                        controller.resume()
                    }
                }
            }
            Text(Copy.startOverBody)
                .font(.subheadline)
                .foregroundStyle(Chalk.inkSoft)
                .padding(.top, 8)
            SecondaryButton(title: Copy.startOverTitle, size: .compact) { confirmStartOver = true }
        }
    }
}

/// The alert diagnostics, one level down from Settings so they don't read as errors.
struct AlertsCheckView: View {
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase
    @State private var rows: [ProfileRow] = []

    static func needsAttention(_ row: ProfileRow) -> Bool {
        row.value == "Off" || row.value == "Not asked yet" || row.value.hasPrefix("On (")
    }

    var body: some View {
        ScreenChrome(top: 8) {
            VStack(alignment: .leading, spacing: 16) {
                StudioTopBar(title: Copy.alertsCheckTitle)
                Text(Copy.alertsCheckBody)
                    .font(.subheadline)
                    .foregroundStyle(Chalk.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)
                ProfileRows(items: rows)
                if rows.contains(where: Self.needsAttention) {
                    Text(Copy.alertsFixHint)
                        .font(.subheadline)
                        .foregroundStyle(Chalk.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                    PrimaryButton(title: Copy.openSettings) {
                        if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                            openURL(url)
                        }
                    }
                }
            }
        }
        .task { rows = await Notifier.diagnostics() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { rows = await Notifier.diagnostics() } }
        }
    }
}

/// A row that opens another screen.
struct SettingsRow: View {
    var title: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.body)
                    .foregroundStyle(Chalk.ink)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Chalk.inkFaint)
            }
            .frame(minHeight: ChalkTokens.minimumTarget)
            .contentShape(Rectangle())
            .overlay(alignment: .bottom) { Rectangle().fill(Chalk.line).frame(height: 1) }
        }
        .buttonStyle(PressFade())
    }
}

/// A time picked from the same choices as setup (UX-26).
struct TimeChoiceRow: View {
    var label: String
    var choices: [ClockTime]
    @Binding var selection: ClockTime

    var body: some View {
        let options = choices.contains(selection) ? choices : (choices + [selection]).sorted { $0.minutesFromMidnight < $1.minutesFromMidnight }
        HStack {
            Text(label)
                .font(.body)
                .foregroundStyle(Chalk.inkSoft)
            Spacer()
            Picker(label, selection: $selection) {
                ForEach(options, id: \.self) { time in
                    Text(Copy.clock(time)).tag(time)
                }
            }
            .pickerStyle(.menu)
            .tint(Chalk.accent)
            .labelsHidden()
        }
        .frame(minHeight: ChalkTokens.minimumTarget)
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
