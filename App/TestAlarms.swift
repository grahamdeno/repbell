import AlarmKit
import Foundation
import RepBellEngine
import SwiftUI

enum TestAlarms {
    private static let storageKey = "repbell.testAlarmIDs"

    @MainActor
    static func authorizationGranted() async -> Bool {
        switch AlarmManager.shared.authorizationState {
        case .authorized:
            return true
        case .denied:
            return false
        case .notDetermined:
            let state = try? await AlarmManager.shared.requestAuthorization()
            return state == .authorized
        @unknown default:
            return false
        }
    }

    /// For Settings: whether test-morning alarms are allowed. Never asks.
    @MainActor
    static func statusLabel() -> String {
        switch AlarmManager.shared.authorizationState {
        case .authorized: return "Allowed"
        case .denied: return "Off"
        case .notDetermined: return "Not asked yet"
        @unknown default: return "Unknown"
        }
    }

    @MainActor
    static func sync(run: PersistedRun?, allows: (Int) -> Bool) async {
        let stored = load()
        for id in stored.values {
            try? AlarmManager.shared.cancel(id: id)
        }
        guard let run, run.pausedAt == nil, !run.ended else {
            save([:])
            return
        }
        let now = CivilDateTime.local(Date())
        let resolved = ScheduleEngine.resolve(run.input, now: now)
        var next: [String: UUID] = [:]
        for day in 1...15 {
            guard allows(day), let scheduled = resolved.day(day) else { continue }
            guard let date = wakeDate(run: run, day: day), date > Date().addingTimeInterval(30) else { continue }
            let id = stored["\(day)"] ?? UUID()
            if scheduled.isTest {
                // Test mornings: the test alarm, until the test is logged.
                guard scheduled.testReps == nil else { continue }
                if await schedule(id: id, at: date, day: day) {
                    next["\(day)"] = id
                }
            } else {
                // Every other program day starts with the morning alarm, which opens the day-start screen.
                if await scheduleMorning(id: id, at: date, day: day, sets: scheduled.sets.count) {
                    next["\(day)"] = id
                }
            }
        }
        save(next)
    }

    @MainActor
    private static func schedule(id: UUID, at date: Date, day: Int) async -> Bool {
        let stop = AlarmButton(text: "Count", textColor: .white, systemImageName: "plus.circle.fill")
        let alert = AlarmPresentation.Alert(
            title: "Test day. As many as you can, good form.",
            stopButton: stop
        )
        let attributes = AlarmAttributes<RepBellAlarmMetadata>(
            presentation: AlarmPresentation(alert: alert),
            metadata: RepBellAlarmMetadata(day: day),
            tintColor: Chalk.accent
        )
        let configuration = AlarmManager.AlarmConfiguration.alarm(
            schedule: .fixed(date),
            attributes: attributes,
            sound: .default
        )
        do {
            _ = try await AlarmManager.shared.schedule(id: id, configuration: configuration)
            return true
        } catch {
            return false
        }
    }

    @MainActor
    private static func scheduleMorning(id: UUID, at date: Date, day: Int, sets: Int) async -> Bool {
        let alert = AlarmPresentation.Alert(
            title: LocalizedStringResource(stringLiteral: Copy.morningAlarm(day: day, sets: sets)),
            stopButton: AlarmButton(text: LocalizedStringResource(stringLiteral: Copy.gotIt), textColor: .white, systemImageName: "checkmark"),
            secondaryButton: AlarmButton(text: LocalizedStringResource(stringLiteral: Copy.startTheDayButton), textColor: .white, systemImageName: "sunrise"),
            secondaryButtonBehavior: .custom
        )
        let attributes = AlarmAttributes<RepBellAlarmMetadata>(
            presentation: AlarmPresentation(alert: alert),
            metadata: RepBellAlarmMetadata(day: day),
            tintColor: Chalk.accent
        )
        let configuration = AlarmManager.AlarmConfiguration.alarm(
            schedule: .fixed(date),
            attributes: attributes,
            stopIntent: GotItIntent(),
            secondaryIntent: StartTheDayIntent(),
            sound: .default
        )
        do {
            _ = try await AlarmManager.shared.schedule(id: id, configuration: configuration)
            return true
        } catch {
            return false
        }
    }

    private static func wakeDate(run: PersistedRun, day: Int) -> Date? {
        let date = run.input.date(forDay: day)
        return CivilDateTime(date: date, hour: run.input.wake.hour, minute: run.input.wake.minute).foundationDate()
    }

    private static func load() -> [String: UUID] {
        guard let raw = UserDefaults.standard.dictionary(forKey: storageKey) as? [String: String] else { return [:] }
        return raw.compactMapValues(UUID.init(uuidString:))
    }

    private static func save(_ ids: [String: UUID]) {
        let raw = ids.mapValues(\.uuidString)
        UserDefaults.standard.set(raw, forKey: storageKey)
    }
}
