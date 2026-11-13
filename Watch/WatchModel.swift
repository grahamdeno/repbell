import Foundation
import RepBellEngine
import WatchConnectivity
import WatchKit

@MainActor
@Observable
final class WatchModel: NSObject, WCSessionDelegate {
    var library = LibraryFile()
    var hasPhone = false

    func start() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    func done(day: Int, index: Int) {
        WKInterfaceDevice.current().play(.success)
        apply(kind: "done", day: day, index: index)
    }

    func snooze(day: Int, index: Int) {
        apply(kind: "snooze", day: day, index: index)
    }

    func resolvedNow() -> ResolvedRun? {
        guard library.current != nil else { return nil }
        let now = library.current?.pausedAt ?? CivilDateTime.local(Date())
        return library.resolved(at: now)
    }

    private func apply(kind: String, day: Int, index: Int) {
        let now = CivilDateTime.local(Date())
        guard var run = library.current else { return }
        switch kind {
        case "done":
            run.input.events.append(.done(day: day, index: index, at: now))
        case "snooze":
            run.input.events.append(.snooze(day: day, index: index, at: now))
        default:
            break
        }
        library.current = run
        guard WCSession.default.activationState == .activated else { return }
        WCSession.default.transferUserInfo(["kind": kind, "day": day, "index": index])
    }

    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        let context = session.receivedApplicationContext
        Task { @MainActor in
            self.consume(context)
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        Task { @MainActor in
            self.consume(applicationContext)
        }
    }

    private func consume(_ context: [String: Any]) {
        guard let data = context["library"] as? Data, let file = try? JSONDecoder().decode(LibraryFile.self, from: data) else { return }
        let incoming = file.current?.input.events.count ?? 0
        let local = library.current?.input.events.count ?? 0
        if file.current != nil && incoming >= local {
            library = file
            hasPhone = true
        } else if library.current == nil {
            library = file
            hasPhone = true
        }
    }
}
