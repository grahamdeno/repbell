import RepBellEngine
import StoreKit

extension Unlocker {
    enum RestoreOutcome { case found, none, unreachable }

    /// Syncs with the App Store, then checks for the unlock. A failed sync (offline, sign-in cancelled) is
    /// reported as unreachable, not as "no purchase".
    static func restore() async -> RestoreOutcome {
        do {
            try await AppStore.sync()
        } catch {
            return await hasUnlock() ? .found : .unreachable
        }
        return await hasUnlock() ? .found : .none
    }
}
