import AlarmKit
import AppIntents
import Foundation
import RepBellEngine
import SwiftUI

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

    /// The set alerts that ring right now, for the notification sound rule.
    @MainActor
    static func ringingIDs(library: LibraryFile) -> Set<String> {
        guard let run = library.current, run.pausedAt == nil, !run.ended else { return [] }
        let now = CivilDateTime.local(Date())
        let pending = ScheduleEngine.resolve(run.input, now: now).alertQueue(at: now).pending
        return Set(RingPlan.ringing(alerts: pending, state: RingStore.state, date: now.date).map(\.id))
    }

    @MainActor
    static func sync(library: LibraryFile, holdUntil: Date?) async {
        for id in load() {
            try? AlarmManager.shared.cancel(id: id)
        }
        guard AlarmManager.shared.authorizationState == .authorized,
              let run = library.current, run.pausedAt == nil, !run.ended else {
            save([])
            return
        }
        let now = CivilDateTime.local(Date())
        let pending = ScheduleEngine.resolve(run.input, now: now).alertQueue(at: now).pending
        var scheduled: [UUID] = []
        for alert in RingPlan.ringing(alerts: pending, state: RingStore.state, date: now.date) {
            guard let date = alert.at.foundationDate(), date > Date().addingTimeInterval(5) else { continue }
            if let holdUntil, date < holdUntil { continue }
            let id = UUID()
            if await schedule(id: id, at: date, alert: alert) {
                scheduled.append(id)
            }
        }
        save(scheduled)
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
            tintColor: Chalk.accent
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

/// "Quiet next" on a ringing set alarm: the next set arrives as a silent banner, and sets stay quiet until one is
/// acknowledged.
struct QuietNextIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Quiet next"
    static var openAppWhenRun = false

    func perform() async throws -> some IntentResult {
        await MainActor.run {
            RingStore.update { $0.quietNext(at: CivilDateTime.local(Date())) }
        }
        await ProgramController.shared.refreshAlerts()
        return .result()
    }
}

/// "Got it" on a ringing set alarm: an acknowledgment, so the next set rings.
struct GotItIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Got it"
    static var openAppWhenRun = false

    func perform() async throws -> some IntentResult {
        await MainActor.run {
            RingStore.update { $0.acknowledge(at: CivilDateTime.local(Date())) }
        }
        await ProgramController.shared.refreshAlerts()
        return .result()
    }
}

/// "Start the day" on the morning alarm: opens Rep Bell to the day-start screen.
struct StartTheDayIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Start the day"
    static var openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        .result()
    }
}
