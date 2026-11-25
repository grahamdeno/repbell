import Foundation
import RepBellEngine
import WatchConnectivity

final class PhoneSessionBridge: NSObject, WCSessionDelegate {
    static let shared = PhoneSessionBridge()

    func start() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    func push(_ library: LibraryFile) {
        guard WCSession.isSupported(), WCSession.default.activationState == .activated else { return }
        guard let data = try? JSONEncoder().encode(library) else { return }
        // The Coach voice in use goes with it (item 19), so the Watch shows a line only when the iPhone would.
        let coach = CoachMode.effective(stored: CoachVoiceStore.mode, paidFeaturesOpen: library.paidFeaturesOpen)
        try? WCSession.default.updateApplicationContext(["library": data, "coach": coach.rawValue])
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            self.push(ProgramController.shared.library)
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }

    /// The Watch asks for the model's line after a set (item 19). The iPhone answers with a line in the voice it has
    /// in use, or an empty reply; the Watch keeps its written line then.
    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        guard let request = CoachVoice.parseWatchRequest(message) else {
            replyHandler([:])
            return
        }
        Task { @MainActor in
            let mode = ProgramController.shared.activeCoachMode
            switch CoachVoice.watchAnswer(phoneMode: mode, watchMode: request.mode) {
            case .clear:
                replyHandler(["clear": true])
            case .keep:
                replyHandler([:])
            case .write:
                if let line = await CoachWriter.generated(mode: mode, facts: request.facts) {
                    replyHandler(["line": line])
                } else {
                    replyHandler([:])
                }
            }
        }
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        Task { @MainActor in
            ProgramController.shared.applyWatch(userInfo)
        }
    }
}
