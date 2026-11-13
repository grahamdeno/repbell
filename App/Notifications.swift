import BackgroundTasks
import Foundation
import RepBellEngine
import StoreKit
import UserNotifications

enum Notifier {
    static let categoryID = "set"
    static let doneAction = "done"
    static let laterAction = "in10"
    static let refreshID = "com.grahamdeno.repbell.refresh"

    static func install() {
        let done = UNNotificationAction(identifier: doneAction, title: Copy.done, options: [])
        let later = UNNotificationAction(identifier: laterAction, title: Copy.inTen, options: [])
        let category = UNNotificationCategory(identifier: categoryID, actions: [done, later], intentIdentifiers: [], options: [])
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }

    static func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        case .denied:
            return false
        @unknown default:
            return false
        }
    }

    static func refill(library: LibraryFile) async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        let ours = pending.map(\.identifier).filter { $0.hasPrefix("set.") || $0.hasPrefix("note.") }
        center.removePendingNotificationRequests(withIdentifiers: ours)
        guard let run = library.current, run.pausedAt == nil, !run.ended else { return }
        let now = CivilDateTime.local(Date())
        let resolved = ScheduleEngine.resolve(run.input, now: now)
        let queue = resolved.alertQueue(at: now)
        for alert in queue.pending where library.allows(day: alert.day) {
            guard let date = alert.at.foundationDate(), date > Date() else { continue }
            let content = UNMutableNotificationContent()
            content.title = Copy.setAlertTitle(reps: alert.reps)
            content.body = Copy.setAlertBody(index: alert.index, total: alert.total, day: alert.day)
            content.sound = .default
            content.categoryIdentifier = categoryID
            content.interruptionLevel = .timeSensitive
            content.threadIdentifier = "day-\(alert.day)"
            let parts = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
            let trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: false)
            let request = UNNotificationRequest(identifier: "set.\(alert.day).\(alert.index)", content: content, trigger: trigger)
            try? await center.add(request)
        }
        var notes = 0
        for note in resolved.notes() where notes < 4 && note.at > now {
            guard shouldSchedule(note, library: library, resolved: resolved) else { continue }
            guard let date = note.at.foundationDate(), date > Date() else { continue }
            let content = UNMutableNotificationContent()
            content.title = Copy.wordmark
            content.body = note.body
            content.sound = .default
            let parts = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
            let trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: false)
            try? await center.add(UNNotificationRequest(identifier: "note.\(note.id)", content: content, trigger: trigger))
            notes += 1
        }
    }

    static func scheduleRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: refreshID)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
        try? BGTaskScheduler.shared.submit(request)
    }

    private static func shouldSchedule(_ note: ScheduledNote, library: LibraryFile, resolved: ResolvedRun) -> Bool {
        switch note.kind {
        case .hardDay:
            return library.allows(day: 9) && resolved.day(9)?.weekTwoMaxIsProvisional == false
        case .testEve:
            if note.id.contains("15") { return library.allows(day: 15) }
            return library.allows(day: 8)
        case .dayEightFallback:
            return library.allows(day: 8) && resolved.day(8)?.testReps == nil
        case .endOfDay:
            let day = Int(note.id.split(separator: ".").last ?? "") ?? 0
            guard library.allows(day: day) else { return false }
            let now = CivilDateTime.local(Date())
            return resolved.day(day)?.date == now.date
        }
    }
}

enum Unlocker {
    static func hasUnlock() async -> Bool {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result, transaction.productID == LibraryFile.unlockProductID {
                return true
            }
        }
        return false
    }

    static func purchase() async -> Bool {
        guard let product = try? await Product.products(for: [LibraryFile.unlockProductID]).first else {
            return false
        }
        guard let result = try? await product.purchase() else { return false }
        switch result {
        case .success(.verified(let transaction)):
            await transaction.finish()
            return true
        default:
            return false
        }
    }

    static func listen() {
        Task {
            for await update in Transaction.updates {
                if case .verified(let transaction) = update, transaction.productID == LibraryFile.unlockProductID {
                    await transaction.finish()
                    await MainActor.run {
                        ProgramController.shared.library.unlocked = true
                        LibraryDisk.save(ProgramController.shared.library)
                    }
                }
            }
        }
    }
}
