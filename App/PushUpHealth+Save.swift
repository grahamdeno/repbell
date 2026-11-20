import Foundation
import HealthKit
import RepBellEngine

/// Writes each finished program day to Apple Health as one strength workout. Write only; off until turned on.
@MainActor
enum PushUpHealthStore {
    private static let store = HKHealthStore()
    private static let enabledKey = "health.pushups"
    private static let writtenKey = "health.pushupsWritten"

    static var enabled: Bool {
        get { UserDefaults.standard.bool(forKey: enabledKey) }
        set { UserDefaults.standard.set(newValue, forKey: enabledKey) }
    }

    private static var written: Set<String> {
        get { Set(UserDefaults.standard.stringArray(forKey: writtenKey) ?? []) }
        set { UserDefaults.standard.set(Array(newValue), forKey: writtenKey) }
    }

    /// Writes any finished days not written yet. A failed write is tried again next time.
    static func sync(run: PersistedRun?) async {
        guard enabled, StudioHealth.canSave else { return }
        let days = PushUpHealth.pending(run: run, now: CivilDateTime.local(Date()), written: written)
        for day in days {
            if await save(day) {
                written.insert(day.key)
            }
        }
    }

    /// Days already finished before the person turned this on are not written backwards.
    static func markExistingAsWritten(run: PersistedRun?) {
        let days = PushUpHealth.pending(run: run, now: CivilDateTime.local(Date()), written: written)
        written.formUnion(days.map(\.key))
    }

    private static func save(_ day: PushUpHealth.Day) async -> Bool {
        guard let end = day.end.foundationDate() else { return false }
        let start = end.addingTimeInterval(-Double(day.minutes * 60))
        let config = HKWorkoutConfiguration()
        config.activityType = .functionalStrengthTraining
        config.locationType = .indoor
        let builder = HKWorkoutBuilder(healthStore: store, configuration: config, device: .local())
        do {
            try await builder.beginCollection(at: start)
            try await builder.addMetadata([
                HKMetadataKeyIndoorWorkout: true,
                "RepBellDay": day.day,
                "RepBellPushUps": day.pushUps,
                "RepBellSets": day.sets,
            ])
            try await builder.endCollection(at: end)
            _ = try await builder.finishWorkout()
            return true
        } catch {
            return false
        }
    }
}
