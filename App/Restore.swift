import RepBellEngine
import StoreKit

extension Unlocker {
    /// Syncs with the App Store, then checks for the unlock.
    static func restore() async -> Bool {
        try? await AppStore.sync()
        return await hasUnlock()
    }
}
