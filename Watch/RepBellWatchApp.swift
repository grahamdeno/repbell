import RepBellEngine
import SwiftUI

@main
struct RepBellWatchApp: App {
    @State private var model = WatchModel()

    var body: some Scene {
        WindowGroup {
            WatchRoot()
                .environment(model)
                .task {
                    FontRegistration.register(bundle: .main)
                    model.start()
                }
        }
    }
}
