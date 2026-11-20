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
        let stored = UserDefaults.standard.object(forKey: indexKey) as? Int
        let next = DeskStretch.next(after: stored)
        UserDefaults.standard.set(next.index, forKey: indexKey)
        lastShown = now
        return next.stretch
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

/// One 30-second stretch after a set. Done or Skip; nothing is recorded either way.
struct DeskStretchView: View {
    var stretch: DeskStretch.Stretch
    var finish: () -> Void

    @State private var remaining = DeskStretch.seconds
    @State private var running = true

    var body: some View {
        ZStack {
            Chalk.ground.ignoresSafeArea()
            ScreenChrome(top: 24) {
                VStack(alignment: .leading, spacing: 18) {
                    Text(Copy.deskStretchTitle)
                        .eyebrow(Chalk.accent)
                    Text(stretch.name)
                        .font(Chalk.display(44))
                        .textCase(.uppercase)
                        .foregroundStyle(Chalk.ink)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(stretch.cues, id: \.self) { cue in
                            Text(cue)
                                .font(.body)
                                .foregroundStyle(Chalk.inkSoft)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    Text(StudioCopy.clock(remaining))
                        .font(Chalk.display(96))
                        .monospacedDigit()
                        .foregroundStyle(remaining == 0 ? Chalk.inkMuted : Chalk.accent)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .accessibilityLabel(Copy.deskStretchTimer(seconds: remaining))
                    if let note = DeskStretch.sideNote(stretch) {
                        Text(note)
                            .font(.subheadline)
                            .foregroundStyle(Chalk.inkMuted)
                    }
                    Spacer(minLength: 12)
                    PrimaryButton(title: Copy.done, action: finish)
                    TextLink(title: Copy.deskStretchSkip, action: finish)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .task {
            while remaining > 0 && !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                remaining -= 1
                if remaining == DeskStretch.seconds / 2 && stretch.eachSide { Haptics.play(.tap) }
            }
            if remaining == 0 { Haptics.play(.setDone) }
        }
    }
}
