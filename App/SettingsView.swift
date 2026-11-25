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
    @State private var pushUpsToHealth = PushUpHealthStore.enabled
    @State private var deskStretchOn = DeskStretchStore.enabled
    @State private var deskStart = DeskStretchStore.startHour
    @State private var deskEnd = DeskStretchStore.endHour
    @State private var showPaywall = false
    @State private var restoring = false
    @State private var coachMode = CoachVoiceStore.mode
    @State private var coachWanted: CoachMode?
    @Environment(\.dynamicTypeSize) private var typeSize

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
                        purchase
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
        .onDisappear { controller.unlockMessage = nil }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
                .environment(controller)
                .presentationBackground(.clear)
        }
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
                    .foregroundStyle(Chalk.inkMuted)
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

    // MARK: Coach voice

    /// Off, Coaching or Push (roadmap item 17). Coaching and Push need the unlock.
    private var coachVoice: some View {
        let selection = Binding<CoachMode>(
            get: { controller.library.paidFeaturesOpen ? coachMode : .off },
            set: { choice in
                if choice != .off && !controller.library.paidFeaturesOpen {
                    coachWanted = choice
                    showPaywall = true
                } else {
                    CoachVoiceStore.mode = choice
                    coachMode = choice
                    CoachWriter.prewarm(mode: choice)
                    Haptics.play(.tap)
                }
            }
        )
        return VStack(alignment: .leading, spacing: 8) {
            Text(Copy.coachVoiceSetting)
                .font(.body)
                .foregroundStyle(Chalk.ink)
            Group {
                if typeSize.isAccessibilitySize {
                    Picker(Copy.coachVoiceSetting, selection: selection) {
                        ForEach(CoachMode.allCases, id: \.self) { Text(Copy.coachModeName($0)).tag($0) }
                    }
                    .pickerStyle(.menu)
                    .tint(Chalk.volt)
                } else {
                    Picker(Copy.coachVoiceSetting, selection: selection) {
                        ForEach(CoachMode.allCases, id: \.self) { Text(Copy.coachModeName($0)).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }
            }
            Text(Copy.coachVoiceNote)
                .font(.subheadline)
                .foregroundStyle(Chalk.inkMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .onChange(of: controller.library.unlocked) { _, open in
            // Someone who bought from the picker gets the voice they picked.
            if open, let wanted = coachWanted {
                CoachVoiceStore.mode = wanted
                CoachWriter.prewarm(mode: wanted)
            }
            coachWanted = nil
            coachMode = CoachVoiceStore.mode
        }
    }

    // MARK: Purchase

    /// Unlock status and Restore purchase (roadmap item 18). The program itself never needs the unlock.
    @ViewBuilder
    private var purchase: some View {
        if Features.payment {
            ProfileSection(Copy.unlockSection) {
                Text(controller.library.unlocked ? Copy.unlocked : Copy.notUnlocked)
                    .font(.body)
                    .foregroundStyle(Chalk.ink)
                if !controller.library.unlocked {
                    Text(Copy.unlockTitle)
                        .font(.subheadline)
                        .foregroundStyle(Chalk.inkMuted)
                    PrimaryButton(title: Copy.unlockButton) { showPaywall = true }
                }
                SecondaryButton(title: Copy.restorePurchase, size: .compact) {
                    guard !restoring else { return }
                    restoring = true
                    Task {
                        await controller.restorePurchases()
                        restoring = false
                    }
                }
                .disabled(restoring)
                if let message = controller.unlockMessage, !showPaywall {
                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(Chalk.inkMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    // MARK: Program

    private var program: some View {
        ProfileSection(Copy.programSection) {
            if let run = controller.library.current, !run.ended {
                if run.pausedAt == nil {
                    Text(Copy.pauseBody)
                        .font(.subheadline)
                        .foregroundStyle(Chalk.inkMuted)
                    SecondaryButton(title: Copy.pauseTitle, size: .compact) {
                        controller.pause()
                    }
                } else {
                    PrimaryButton(title: Copy.resume) {
                        controller.resume()
                    }
                }
            }
            coachVoice
            Toggle(Copy.deskStretchSetting, isOn: Binding(
                get: { deskStretchOn },
                set: { on in
                    DeskStretchStore.enabled = on
                    deskStretchOn = on
                    Task { await controller.refreshAlerts() }
                }
            ))
            .tint(Chalk.volt)
            .foregroundStyle(Chalk.inkMuted)
            .frame(minHeight: ChalkTokens.minimumTarget)
            Text(Copy.deskStretchDetail)
                .font(.footnote)
                .foregroundStyle(Chalk.inkMuted)
                .fixedSize(horizontal: false, vertical: true)
            if deskStretchOn {
                hourPicker(Copy.deskStretchFrom, hours: Array(DeskStretch.windowHours), selection: Binding(
                    get: { deskStart },
                    set: { hour in
                        let window = DeskStretch.window(start: hour, end: max(deskEnd, hour))
                        deskStart = window.start
                        deskEnd = window.end
                        saveDeskWindow()
                    }
                ))
                hourPicker(Copy.deskStretchUntil, hours: Array(deskStart...DeskStretch.windowHours.upperBound), selection: Binding(
                    get: { deskEnd },
                    set: { hour in
                        deskEnd = DeskStretch.window(start: deskStart, end: hour).end
                        saveDeskWindow()
                    }
                ))
            }
            if StudioHealth.available {
                Toggle(Copy.pushUpsToHealth, isOn: Binding(
                    get: { pushUpsToHealth },
                    set: { on in
                        if on {
                            Task {
                                let allowed = await StudioHealth.enable()
                                if allowed { PushUpHealthStore.markExistingAsWritten(run: controller.library.current) }
                                PushUpHealthStore.enabled = allowed
                                pushUpsToHealth = allowed
                            }
                        } else {
                            PushUpHealthStore.enabled = false
                            pushUpsToHealth = false
                        }
                    }
                ))
                .tint(Chalk.volt)
                .foregroundStyle(Chalk.inkMuted)
                .frame(minHeight: ChalkTokens.minimumTarget)
                Text(Copy.pushUpsToHealthDetail)
                    .font(.footnote)
                    .foregroundStyle(Chalk.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Text(Copy.startOverBody)
                .font(.subheadline)
                .foregroundStyle(Chalk.inkMuted)
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
                        .foregroundStyle(Chalk.inkMuted)
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
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        // A time saved by an earlier build may sit off the grid; it's kept, in order from the first choice.
        let first = choices.first?.minutesFromMidnight ?? 0
        let order = { (time: ClockTime) in (time.minutesFromMidnight - first + 1440) % 1440 }
        let options = choices.contains(selection) ? choices : (choices + [selection]).sorted { order($0) < order($1) }
        let picker = Picker(label, selection: $selection) {
            ForEach(options, id: \.self) { time in
                Text(Copy.clock(time)).tag(time)
            }
        }
        .pickerStyle(.menu)
        .tint(Chalk.volt)
        .labelsHidden()
        .frame(minHeight: ChalkTokens.minimumTarget)
        let title = Text(label)
            .font(.body)
            .foregroundStyle(Chalk.inkMuted)
            .accessibilityHidden(true)
        // Stacked at accessibility sizes, so the label and the time never overlap.
        Group {
            if typeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 0) {
                    title
                    picker
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                HStack {
                    title
                    Spacer()
                    picker
                }
            }
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

// Item 20: the hourly desk stretch window.
extension SettingsView {
    func hourPicker(_ label: String, hours: [Int], selection: Binding<Int>) -> some View {
        Picker(label, selection: selection) {
            ForEach(hours, id: \.self) { Text(Copy.hourLabel($0)).tag($0) }
        }
        .pickerStyle(.menu)
        .tint(Chalk.volt)
        .foregroundStyle(Chalk.inkMuted)
        .frame(minHeight: ChalkTokens.minimumTarget)
    }

    func saveDeskWindow() {
        DeskStretchStore.startHour = deskStart
        DeskStretchStore.endHour = deskEnd
        Haptics.play(.tap)
        Task { await controller.refreshAlerts() }
    }
}
