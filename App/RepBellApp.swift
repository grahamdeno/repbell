import BackgroundTasks
import RepBellEngine
import SwiftUI
import UIKit
import UserNotifications

@main
struct RepBellApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(ProgramController.shared)
                .preferredColorScheme(.dark)
                .tint(Chalk.accent)
        }
    }
}

struct RootView: View {
    @Environment(ProgramController.self) private var controller
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            switch controller.screen {
            case .promise: PromiseView()
            case .wake: WakeView()
            case .bed: BedView()
            case .startDay: StartDayView()
            case .alerts: AlertsView()
            case .ready: ReadyView()
            case .counter(let day): CounterView(day: day)
            case .confirm(let day, let reps): ConfirmView(day: day, reps: reps)
            case .today: TodayView()
            case .hurts: HurtsView()
            case .result: ResultView()
            case .about: AboutView()
            case .paywall: PaywallView()
            case .profile: ProfileView()
            }
        }
        .task {
            FontRegistration.register(bundle: .main)
            await controller.onActive()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                Task { await controller.onActive() }
            }
        }
        .onOpenURL { url in
            if url.host == "test", let run = controller.library.current {
                let now = CivilDateTime.local(Date())
                let day = run.input.dayNumber(on: now.date) ?? 1
                controller.openCounter(day: day, preserve: false)
            }
        }
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FontRegistration.register(bundle: .main)
        UNUserNotificationCenter.current().delegate = self
        Notifier.install()
        PhoneSessionBridge.shared.start()
        Unlocker.listen()
        BGTaskScheduler.shared.register(forTaskWithIdentifier: Notifier.refreshID, using: nil) { task in
            guard let refresh = task as? BGAppRefreshTask else { return }
            refresh.expirationHandler = {}
            Task { @MainActor in
                await ProgramController.shared.refreshAlerts()
                refresh.setTaskCompleted(success: true)
            }
        }
        Notifier.scheduleRefresh()
        return true
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .list]
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        await MainActor.run {
            ProgramController.shared.handleNotification(action: response.actionIdentifier, identifier: response.notification.request.identifier)
        }
    }
}
