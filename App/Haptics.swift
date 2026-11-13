import CoreHaptics
import UIKit

/// Strong, playful haptic patterns for the app's success moments.
/// Only plays while the app is on screen; iOS plays its own tap for notification actions.
@MainActor
enum Haptics {
    enum Moment {
        case tap
        case setDone
        case dayComplete
        case testLogged
        case result
    }

    private static var engine: CHHapticEngine?

    static func play(_ moment: Moment) {
        guard UIApplication.shared.applicationState == .active else { return }
        guard let engine = readyEngine() else {
            fallback(moment)
            return
        }
        do {
            let pattern = try CHHapticPattern(events: events(for: moment), parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try engine.start()
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            fallback(moment)
        }
    }

    private static func readyEngine() -> CHHapticEngine? {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return nil }
        if let engine { return engine }
        guard let made = try? CHHapticEngine() else { return nil }
        made.isAutoShutdownEnabled = true
        made.resetHandler = { [weak made] in try? made?.start() }
        made.stoppedHandler = { _ in }
        engine = made
        return made
    }

    private static func hit(_ time: TimeInterval, _ intensity: Float, _ sharpness: Float) -> CHHapticEvent {
        CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness),
            ],
            relativeTime: time
        )
    }

    private static func rumble(_ time: TimeInterval, _ duration: TimeInterval, _ intensity: Float, _ sharpness: Float) -> CHHapticEvent {
        CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness),
            ],
            relativeTime: time,
            duration: duration
        )
    }

    private static func events(for moment: Moment) -> [CHHapticEvent] {
        switch moment {
        case .tap:
            return [hit(0, 0.7, 0.7)]
        case .setDone:
            // Quick double tap, then a firm thump.
            return [
                hit(0, 0.75, 0.9),
                hit(0.09, 0.85, 0.9),
                hit(0.22, 1.0, 0.3),
                rumble(0.22, 0.14, 0.8, 0.2),
            ]
        case .dayComplete:
            // Rising four-beat roll ending in a big hit.
            return [
                hit(0, 0.5, 0.8),
                hit(0.1, 0.65, 0.8),
                hit(0.2, 0.8, 0.8),
                hit(0.3, 0.92, 0.8),
                hit(0.48, 1.0, 0.25),
                rumble(0.48, 0.3, 1.0, 0.15),
            ]
        case .testLogged:
            // Heavy drumroll, then a snap.
            var roll: [CHHapticEvent] = (0..<11).map { step in
                let t = Double(step) * 0.045
                return hit(t, 0.4 + Float(step) * 0.05, 0.5)
            }
            roll.append(hit(0.6, 1.0, 1.0))
            roll.append(rumble(0.6, 0.18, 0.9, 0.4))
            return roll
        case .result:
            // Long build to a double hit.
            var build: [CHHapticEvent] = (0..<16).map { step in
                let t = Double(step) * 0.06
                return hit(t, 0.3 + Float(step) * 0.04, 0.6)
            }
            build.append(rumble(0, 0.95, 0.35, 0.3))
            build.append(hit(1.05, 1.0, 0.5))
            build.append(rumble(1.05, 0.15, 1.0, 0.2))
            build.append(hit(1.25, 1.0, 0.5))
            build.append(rumble(1.25, 0.4, 1.0, 0.15))
            return build
        }
    }

    private static func fallback(_ moment: Moment) {
        switch moment {
        case .tap:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .setDone:
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        default:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
}
