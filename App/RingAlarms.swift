import AlarmKit
import AppIntents
import Foundation
import RepBellEngine
import SwiftUI

/// Handles the alarm buttons (the intents live in the engine so the widget extension has them too).
@MainActor
enum RingActions {
    static func install() {
        RingIntents.handler = { action in
            await MainActor.run {
                let now = CivilDateTime.local(Date())
                switch action {
                case .quietNext: RingStore.update { $0.quietNext(at: now) }
                case .gotIt: RingStore.update { $0.acknowledge(at: now) }
                case .startTheDay: break
                }
            }
            await ProgramController.shared.refreshAlerts()
        }
    }
}

/// Day start and set alarms that ring through silent (roadmap item 13).
/// The rules live in the engine (`RingPlan`, `RingState`); this file stores the state and talks to AlarmKit.
@MainActor
enum RingStore {
    private static let key = "ring.state"

    static var state: RingState {
        get {
            guard let data = UserDefaults.standard.data(forKey: key),
                  let state = try? JSONDecoder().decode(RingState.self, from: data) else { return RingState() }
            return state
        }
        set {
            var trimmed = newValue
            trimmed.trim(before: CivilDateTime.local(Date()).date)
            if let data = try? JSONEncoder().encode(trimmed) {
                UserDefaults.standard.set(data, forKey: key)
            }
        }
    }

    static func update(_ body: (inout RingState) -> Void) {
        var current = state
        body(&current)
        state = current
    }
}

/// Set alarms on Ring days. Scheduled ahead in a small queue and replaced on every refresh.
enum SetAlarms {
    private static let storageKey = "repbell.setAlarmIDs"

    /// Replaces the scheduled set alarms. Returns the set alerts that will actually ring, so their notifications go
    /// out without sound and nothing rings twice. Alerts that couldn't be scheduled keep their sound.
    @MainActor
    @discardableResult
    static func sync(library: LibraryFile, holdUntil: Date?) async -> Set<String> {
        for id in load() {
            try? AlarmManager.shared.cancel(id: id)
        }
        guard AlarmManager.shared.authorizationState == .authorized,
              let run = library.current, run.pausedAt == nil, !run.ended else {
            save([])
            return []
        }
        let now = CivilDateTime.local(Date())
        let resolved = ScheduleEngine.resolve(run.input, now: now)
        let wake = ScheduleEngine.window(for: run.input, at: now).wake
        let todayIsTest = run.input.dayNumber(on: now.date).flatMap { resolved.day($0)?.isTest } ?? false
        var scheduled: [UUID] = []
        var ringing: Set<String> = []
        for alert in RingPlan.ringing(alerts: resolved.alertQueue(at: now).pending, state: RingStore.state, date: now.date) {
            // The morning alarm already rings at wake time on ordinary days; that set keeps its banner and sound.
            if !todayIsTest && alert.at.minutes == wake.minutesFromMidnight { continue }
            guard let date = alert.at.foundationDate(), date > Date().addingTimeInterval(5) else { continue }
            if let holdUntil, date < holdUntil { continue }
            let id = UUID()
            if await schedule(id: id, at: date, alert: alert) {
                scheduled.append(id)
                ringing.insert(alert.id)
            }
        }
        save(scheduled)
        return ringing
    }

    @MainActor
    private static func schedule(id: UUID, at date: Date, alert: QueuedAlert) async -> Bool {
        let presentation = AlarmPresentation(
            alert: AlarmPresentation.Alert(
                title: LocalizedStringResource(stringLiteral: Copy.setAlertTitle(reps: alert.reps)),
                stopButton: AlarmButton(text: LocalizedStringResource(stringLiteral: Copy.gotIt), textColor: .white, systemImageName: "checkmark"),
                secondaryButton: AlarmButton(text: LocalizedStringResource(stringLiteral: Copy.quietNext), textColor: .white, systemImageName: "bell.slash"),
                secondaryButtonBehavior: .custom
            )
        )
        let attributes = AlarmAttributes<RepBellAlarmMetadata>(
            presentation: presentation,
            metadata: RepBellAlarmMetadata(day: alert.day),
            tintColor: Chalk.amber
        )
        let configuration = AlarmManager.AlarmConfiguration.alarm(
            schedule: .fixed(date),
            attributes: attributes,
            stopIntent: GotItIntent(),
            secondaryIntent: QuietNextIntent(),
            sound: .default
        )
        do {
            _ = try await AlarmManager.shared.schedule(id: id, configuration: configuration)
            return true
        } catch {
            return false
        }
    }

    private static func load() -> [UUID] {
        (UserDefaults.standard.stringArray(forKey: storageKey) ?? []).compactMap(UUID.init(uuidString:))
    }

    private static func save(_ ids: [UUID]) {
        UserDefaults.standard.set(ids.map(\.uuidString), forKey: storageKey)
    }
}
