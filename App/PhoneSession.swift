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
        try? WCSession.default.updateApplicationContext(["library": data])
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

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        Task { @MainActor in
            ProgramController.shared.applyWatch(userInfo)
        }
    }
}
