import RepBellEngine
import SwiftUI
import UIKit
import UserNotifications

/// Desk stretch settings and the last one shown. Kept apart from the run.
@MainActor
enum DeskStretchStore {
    private static let enabledKey = "deskStretch.enabled"
    private static let lastShownKey = "deskStretch.lastShown"
    private static let indexKey = "deskStretch.index"
    private static let bagKey = "deskStretch.bag"

    static var enabled: Bool {
        get { UserDefaults.standard.bool(forKey: enabledKey) }
        set { UserDefaults.standard.set(newValue, forKey: enabledKey) }
    }

    static var lastShown: CivilDateTime? {
        get {
            guard let data = UserDefaults.standard.data(forKey: lastShownKey) else { return nil }
            return try? JSONDecoder().decode(CivilDateTime.self, from: data)
        }
        set {
            UserDefaults.standard.set(newValue.flatMap { try? JSONEncoder().encode($0) }, forKey: lastShownKey)
        }
    }

    /// The stretch due after a set logged now, if any. Marks it shown.
    static func takeDue(now: CivilDateTime) -> DeskStretch.Stretch? {
        guard DeskStretch.isDue(enabled: enabled, lastShown: lastShown, now: now) else { return nil }
        let last = UserDefaults.standard.object(forKey: indexKey) as? Int
        let bag = UserDefaults.standard.array(forKey: bagKey) as? [Int] ?? []
        var random = SystemRandomNumberGenerator()
        let next = DeskStretch.next(bag: bag, last: last, using: &random)
        UserDefaults.standard.set(next.index, forKey: indexKey)
        UserDefaults.standard.set(next.bag, forKey: bagKey)
        lastShown = now
        return DeskStretch.all[next.index]
    }

    /// When the set was logged from an alert or the Watch, the stretch arrives as a quiet notification.
    static func notify(_ stretch: DeskStretch.Stretch) {
        let content = UNMutableNotificationContent()
        content.title = Copy.deskStretchTitle
        content.body = Copy.deskStretchNotice(name: stretch.name, cue: stretch.cues.first ?? "", seconds: DeskStretch.seconds)
        content.sound = nil
        content.threadIdentifier = "desk-stretch"
        let request = UNNotificationRequest(identifier: "stretch.\(stretch.id)", content: content, trigger: UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false))
        UNUserNotificationCenter.current().add(request)
    }
}

/// One stretch after a set: a start screen, a get-ready, the hold (each side on its own), then done.
/// Nothing counts until Start. The only big Done is at the end.
struct DeskStretchView: View {
    var stretch: DeskStretch.Stretch
    var finish: () -> Void

    private enum Stage: Equatable { case ready, running(Int), finished }

    @State private var stage: Stage = .ready
    @State private var remaining = 0

    private var phases: [DeskStretch.Phase] { DeskStretch.phases(stretch) }

    private var isRunning: Bool {
        if case .running = stage { return true }
        return false
    }

    var body: some View {
        ZStack {
            Chalk.ground.ignoresSafeArea()
            ScreenChrome(top: 24) {
                VStack(alignment: .leading, spacing: 18) {
                    Text(Copy.deskStretchTitle)
                        .eyebrow(Chalk.volt)
                    Text(stretch.name)
                        .font(Chalk.display(40))
                        .textCase(.uppercase)
                        .foregroundStyle(Chalk.ink)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(stretch.cues, id: \.self) { cue in
                            Text(cue)
                                .font(.body)
                                .foregroundStyle(Chalk.inkMuted)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    if let clip = Figures.clip(stretch.id) {
                        // Moves through the stretch while it runs; shows the position, still, before and after.
                        FigureStage(clip: clip, still: !isRunning)
                            .frame(maxWidth: .infinity)
                            .frame(height: 180)
                            .background(Chalk.surface, in: RoundedRectangle(cornerRadius: 20))
                    }
                    stageView
                    Spacer(minLength: 12)
                    controls
                }
            }
        }
        .task(id: stage) { await run() }
    }

    @ViewBuilder
    private var stageView: some View {
        switch stage {
        case .ready:
            Text(DeskStretch.sideNote(stretch) ?? Copy.deskStretchSeconds(DeskStretch.seconds))
                .font(.subheadline)
                .foregroundStyle(Chalk.inkMuted)
        case .running(let index):
            VStack(alignment: .leading, spacing: 4) {
                Text(label(phases[index].kind))
                    .font(Chalk.display(32, weight: .bold))
                    .textCase(.uppercase)
                    .foregroundStyle(isHold(phases[index].kind) ? Chalk.volt : Chalk.inkMuted)
                    .accessibilityAddTraits(.updatesFrequently)
                Text(StudioCopy.clock(remaining))
                    .font(Chalk.display(96))
                    .monospacedDigit()
                    .foregroundStyle(isHold(phases[index].kind) ? Chalk.volt : Chalk.inkMuted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .accessibilityLabel(Copy.deskStretchTimer(seconds: remaining))
            }
        case .finished:
            Text(Copy.stretchDone)
                .font(Chalk.display(48))
                .textCase(.uppercase)
                .foregroundStyle(Chalk.ink)
        }
    }

    @ViewBuilder
    private var controls: some View {
        switch stage {
        case .ready:
            PrimaryButton(title: Copy.deskStretchStart) { stage = .running(0) }
            TextLink(title: Copy.deskStretchSkip, action: finish)
                .frame(maxWidth: .infinity)
        case .running:
            TextLink(title: Copy.deskStretchEndEarly, action: finish)
                .frame(maxWidth: .infinity)
        case .finished:
            PrimaryButton(title: Copy.done, action: finish)
        }
    }

    private func run() async {
        guard case .running(let index) = stage, index < phases.count else { return }
        let phase = phases[index]
        remaining = phase.seconds
        announce(phase.kind)
        while remaining > 0 {
            try? await Task.sleep(for: .seconds(1))
            if Task.isCancelled { return }
            remaining -= 1
        }
        if index + 1 < phases.count {
            stage = .running(index + 1)
        } else {
            Haptics.play(.setDone)
            UIAccessibility.post(notification: .announcement, argument: Copy.stretchDone)
            stage = .finished
        }
    }

    private func announce(_ kind: DeskStretch.PhaseKind) {
        if case .getInPosition = kind {} else { Haptics.play(.tap) }
        UIAccessibility.post(notification: .announcement, argument: label(kind))
    }

    private func label(_ kind: DeskStretch.PhaseKind) -> String {
        switch kind {
        case .getInPosition: return Copy.getInPosition
        case .switchSides: return Copy.switchSidesTitle
        case .hold(let side):
            switch side {
            case "left": return Copy.leftSide
            case "right": return Copy.rightSide
            default: return Copy.holdIt
            }
        }
    }

    private func isHold(_ kind: DeskStretch.PhaseKind) -> Bool {
        if case .hold = kind { return true }
        return false
    }
}
