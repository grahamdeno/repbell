import Foundation
import HealthKit

/// Saves finished Studio sessions to Apple Health as workouts. Off until turned on in Profile.
enum StudioHealth {
    private static let store = HKHealthStore()

    static var available: Bool { HKHealthStore.isHealthDataAvailable() }

    /// Asks for permission to save workouts. Returns false if Health isn't available or the request fails.
    static func enable() async -> Bool {
        guard available else { return false }
        do {
            try await store.requestAuthorization(toShare: [HKObjectType.workoutType()], read: [])
            return true
        } catch {
            return false
        }
    }

    static func save(session: StudioSession, seconds: Int) async {
        guard available, seconds >= 60 else { return }
        let end = Date()
        let start = end.addingTimeInterval(-Double(seconds))
        let config = HKWorkoutConfiguration()
        config.activityType = activityType(session.id)
        config.locationType = .indoor
        let builder = HKWorkoutBuilder(healthStore: store, configuration: config, device: .local())
        do {
            try await builder.beginCollection(at: start)
            try await builder.addMetadata([
                HKMetadataKeyIndoorWorkout: true,
                "RepBellSession": session.name,
            ])
            try await builder.endCollection(at: end)
            _ = try await builder.finishWorkout()
        } catch {
            // A failed save never affects the Studio log.
        }
    }

    static func activityType(_ id: String) -> HKWorkoutActivityType {
        switch id {
        case "flow-45", "flow-90": return .yoga
        case "stretch": return .flexibility
        case "strike": return .kickboxing
        case "core", "ab-finisher": return .coreTraining
        case "upper", "lower-back", "shoulders-arms": return .functionalStrengthTraining
        case "jump": return .highIntensityIntervalTraining
        case "easy-cardio": return .mixedCardio
        default: return .other
        }
    }
}
