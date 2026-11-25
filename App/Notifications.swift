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

    /// Builds the full set of requests the run needs, removes only stale ones, then adds or replaces the rest.
    /// Callers must not run two refills at once; ProgramController serializes them.
    @discardableResult
    static func refill(library: LibraryFile, holdUntil: Date? = nil, ringing: Set<String> = [], quiet: Bool = false) async -> AlertReport {
        let center = UNUserNotificationCenter.current()
        let desired = desiredRequests(library: library, holdUntil: holdUntil, ringing: ringing, quiet: quiet)
        let wanted = Set(desired.map(\.identifier))
        let pending = await center.pendingNotificationRequests()
        let stale = pending.map(\.identifier).filter {
            ($0.hasPrefix("set.") || $0.hasPrefix("note.") || $0.hasPrefix("desk.")) && !wanted.contains($0)
        }
        if !stale.isEmpty {
            center.removePendingNotificationRequests(withIdentifiers: stale)
        }
        var added = 0
        var lastError: String?
        for request in desired {
            do {
                try await center.add(request)
                added += 1
            } catch {
                lastError = error.localizedDescription
            }
        }
        let report = AlertReport(at: Date(), wanted: desired.count, added: added, error: lastError)
        report.save()
        return report
    }

    private static func desiredRequests(library: LibraryFile, holdUntil: Date?, ringing: Set<String>, quiet: Bool) -> [UNNotificationRequest] {
        let now = CivilDateTime.local(Date())
        var requests = programRequests(library: library, holdUntil: holdUntil, ringing: ringing, quiet: quiet, now: now)
        // Item 20: the hourly desk stretch runs with or without a program, in the slots the set alerts leave.
        var bells: [CivilDateTime] = []
        if let run = library.current, run.pausedAt == nil, !run.ended {
            bells = ScheduleEngine.resolve(run.input, now: now).alertQueue(at: now, capacity: Int.max).pending
                .filter { library.allows(day: $0.day) }.map(\.at)
        }
        let setCount = requests.filter { $0.identifier.hasPrefix("set.") }.count
        requests += deskStretchRequests(now: now, bells: bells, budget: DeskStretch.hourlyBudget(setAlerts: setCount, notes: 4))
        return requests
    }

    private static func deskStretchRequests(now: CivilDateTime, bells: [CivilDateTime], budget: Int) -> [UNNotificationRequest] {
        guard DeskStretchStore.enabled, budget > 0 else { return [] }
        let slots = DeskStretch.hourlySlots(after: now, start: DeskStretchStore.startHour, end: DeskStretchStore.endHour,
                                            setAlerts: bells, lastDone: DeskStretchStore.lastShown, limit: budget)
        let indices = DeskStretch.stretchIndices(for: slots, previous: DeskStretchStore.lastIndex)
        return zip(slots, indices).compactMap { slot, index in
            guard let date = slot.foundationDate(), date > Date() else { return nil }
            let stretch = DeskStretch.all[index]
            let content = UNMutableNotificationContent()
            content.title = Copy.deskStretchTitle
            content.body = Copy.deskStretchNotice(name: stretch.name, cue: stretch.cues.first ?? "", seconds: DeskStretch.seconds)
            content.sound = nil
            content.threadIdentifier = "desk-stretch"
            let id = "desk.\(stretch.id).\(slot.date.dayNumber).\(slot.minutes / 60)"
            return UNNotificationRequest(identifier: id, content: content, trigger: trigger(for: date))
        }
    }

    private static func programRequests(library: LibraryFile, holdUntil: Date?, ringing: Set<String>, quiet: Bool,
                                        now: CivilDateTime) -> [UNNotificationRequest] {
        guard let run = library.current, run.pausedAt == nil, !run.ended else { return [] }
        let resolved = ScheduleEngine.resolve(run.input, now: now)
        var requests: [UNNotificationRequest] = []
        for alert in resolved.alertQueue(at: now).pending where library.allows(day: alert.day) {
            guard let date = alert.at.foundationDate(), date > Date() else { continue }
            // During a Studio session, set alerts wait. The set stays due until the next one, so nothing is lost.
            if let holdUntil, date < holdUntil { continue }
            let content = UNMutableNotificationContent()
            content.title = Copy.setAlertTitle(reps: alert.reps)
            content.body = Copy.setAlertBody(index: alert.index, total: alert.total, day: alert.day)
            // A ringing set has its alarm; after Quiet next, sets are silent banners until one is acknowledged.
            content.sound = (ringing.contains(alert.id) || quiet) ? nil : .default
            content.categoryIdentifier = categoryID
            content.interruptionLevel = .timeSensitive
            content.threadIdentifier = "day-\(alert.day)"
            requests.append(UNNotificationRequest(identifier: "set.\(alert.day).\(alert.index)", content: content, trigger: trigger(for: date)))
        }
        var notes = 0
        for note in resolved.notes() where notes < 4 && note.at > now {
            guard shouldSchedule(note, library: library, resolved: resolved) else { continue }
            guard let date = note.at.foundationDate(), date > Date() else { continue }
            let content = UNMutableNotificationContent()
            content.title = Copy.wordmark
            content.body = note.body
            content.sound = .default
            requests.append(UNNotificationRequest(identifier: "note.\(note.id)", content: content, trigger: trigger(for: date)))
            notes += 1
        }
        return requests
    }

    private static func trigger(for date: Date) -> UNNotificationTrigger {
        let seconds = date.timeIntervalSinceNow
        if seconds < 3600 {
            // Close alerts use an interval trigger so a calendar match can never be skipped.
            return UNTimeIntervalNotificationTrigger(timeInterval: max(1, seconds), repeats: false)
        }
        var parts = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        parts.timeZone = TimeZone.current
        return UNCalendarNotificationTrigger(dateMatching: parts, repeats: false)
    }

    /// Fires a sample set alert in 10 seconds so the person can lock the phone or switch apps and see it arrive.
    static func sendTestAlert() async -> Bool {
        guard await requestAuthorization() else { return false }
        let content = UNMutableNotificationContent()
        content.title = Copy.testAlertTitle
        content.body = Copy.testAlertBody
        content.sound = .default
        content.categoryIdentifier = categoryID
        content.interruptionLevel = .timeSensitive
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 10, repeats: false)
        do {
            try await UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: "check.test", content: content, trigger: trigger))
            return true
        } catch {
            AlertReport(at: Date(), wanted: 1, added: 0, error: error.localizedDescription).save()
            return false
        }
    }

    static func isAuthorized() async -> Bool {
        let status = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
        return status == .authorized || status == .provisional || status == .ephemeral
    }

    /// Live picture of what iOS will and won't do with Rep Bell's alerts.
    static func diagnostics() async -> [ProfileRow] {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        let pending = await center.pendingNotificationRequests().filter { $0.identifier.hasPrefix("set.") }
        var rows: [ProfileRow] = []
        rows.append(ProfileRow(label: "Permission", value: label(settings.authorizationStatus)))
        rows.append(ProfileRow(label: "Banners", value: label(settings.alertSetting, style: settings.alertStyle)))
        rows.append(ProfileRow(label: "Sound", value: label(settings.soundSetting)))
        rows.append(ProfileRow(label: "Time Sensitive", value: label(settings.timeSensitiveSetting)))
        if settings.scheduledDeliverySetting == .enabled {
            rows.append(ProfileRow(label: "Scheduled Summary", value: "On (alerts held back)"))
        }
        rows.append(ProfileRow(label: "Test-day alarm", value: await TestAlarms.statusLabel()))
        rows.append(ProfileRow(label: "Set alerts queued", value: "\(pending.count)"))
        let next = pending.compactMap { request -> Date? in
            if let calendar = request.trigger as? UNCalendarNotificationTrigger { return calendar.nextTriggerDate() }
            if let interval = request.trigger as? UNTimeIntervalNotificationTrigger { return interval.nextTriggerDate() }
            return nil
        }.min()
        if let next {
            rows.append(ProfileRow(label: "Next alert", value: next.formatted(date: .abbreviated, time: .shortened)))
        }
        if let report = AlertReport.load(), let error = report.error {
            rows.append(ProfileRow(label: "Last error", value: error))
        }
        return rows
    }

    private static func label(_ status: UNAuthorizationStatus) -> String {
        switch status {
        case .authorized: return "Allowed"
        case .denied: return "Off"
        case .notDetermined: return "Not asked yet"
        case .provisional: return "Quiet only"
        case .ephemeral: return "Temporary"
        @unknown default: return "Unknown"
        }
    }

    private static func label(_ setting: UNNotificationSetting, style: UNAlertStyle? = nil) -> String {
        switch setting {
        case .enabled:
            if let style, style == .none { return "Off" }
            return "On"
        case .disabled: return "Off"
        case .notSupported: return "Not supported"
        @unknown default: return "Unknown"
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

struct AlertReport: Codable {
    var at: Date
    var wanted: Int
    var added: Int
    var error: String?

    private static let key = "repbell.alertReport"

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Self.key)
        }
    }

    static func load() -> AlertReport? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(AlertReport.self, from: data)
    }
}

enum Unlocker {
    static func hasUnlock() async -> Bool {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result, transaction.productID == LibraryFile.unlockProductID,
               transaction.revocationDate == nil {
                return true
            }
        }
        return false
    }

    enum Outcome { case bought, cancelled, pending, failed, unavailable }

    static func product() async -> Product? {
        try? await Product.products(for: [LibraryFile.unlockProductID]).first
    }

    /// The store's own price for this person's storefront, never a price written in the app.
    static func price() async -> String? {
        await product()?.displayPrice
    }

    static func purchase() async -> Outcome {
        guard let product = await product() else { return .unavailable }
        let result: Product.PurchaseResult
        do {
            result = try await product.purchase()
        } catch {
            return .failed
        }
        switch result {
        case .success(.verified(let transaction)):
            await transaction.finish()
            return .bought
        case .success(.unverified):
            return .failed
        case .pending:
            return .pending
        case .userCancelled:
            return .cancelled
        @unknown default:
            return .failed
        }
    }

    static func listen() {
        Task {
            for await update in Transaction.updates {
                if case .verified(let transaction) = update, transaction.productID == LibraryFile.unlockProductID {
                    await transaction.finish()
                    // A refund arrives as an update too; re-read the entitlement so it can lock again.
                    let open = await hasUnlock()
                    await MainActor.run { ProgramController.shared.setUnlocked(open) }
                }
            }
        }
    }
}
