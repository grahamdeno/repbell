import RepBellEngine
import SwiftUI

@main
struct RepBellWatchApp: App {
    @State private var model = WatchModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            WatchRoot()
                .environment(model)
                .task {
                    FontRegistration.register(bundle: .main)
                    model.start()
                }
                // A coach line left from earlier doesn't greet the person next time, like the iPhone.
                .onChange(of: scenePhase) { _, phase in
                    if phase == .background { model.clearCoachLine() }
                }
        }
    }
}
