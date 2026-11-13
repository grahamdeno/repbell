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
        for day in [1, 8, 15] {
            guard allows(day), resolved.day(day)?.testReps == nil else { continue }
            guard let date = wakeDate(run: run, day: day), date > Date().addingTimeInterval(30) else { continue }
            let id = stored["\(day)"] ?? UUID()
            if await schedule(id: id, at: date, day: day) {
                next["\(day)"] = id
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
            tintColor: Color(red: 1, green: 106.0 / 255, blue: 19.0 / 255)
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
