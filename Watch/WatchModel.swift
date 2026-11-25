import Foundation
import RepBellEngine
import WatchConnectivity
import WatchKit

@MainActor
@Observable
final class WatchModel: NSObject, WCSessionDelegate {
    var library = LibraryFile()
    var hasPhone = false
    /// The Coach voice the iPhone has in use (item 19); off until the iPhone says otherwise.
    var coachMode: CoachMode = .off
    /// The coach line on screen after a set logged here; it stays until tapped away.
    var coachLine: String?
    /// When the line went up; a set due after this takes the screen back.
    var coachShownAt = CivilDateTime.local(Date())
    private var coachToken = 0

    func start() {
        #if DEBUG
        // Screenshot mode: `-RBScreenshot watch-<state>` loads a seeded run and skips the phone.
        if let state = ScreenshotSeeds.requestedState(), state.hasPrefix("watch-") {
            let phoneState = "today-" + state.dropFirst("watch-".count)
            if let seed = ScreenshotSeeds.library(for: phoneState) {
                library = seed.library
                hasPhone = true
            }
            return
        }
        #endif
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    func done(day: Int, index: Int) {
        let before = library.current.flatMap { run in
            ScheduleEngine.resolve(run.input, now: CivilDateTime.local(Date())).day(day)?.sets.first { $0.index == index }?.status
        }
        WKInterfaceDevice.current().play(.success)
        apply(kind: "done", day: day, index: index)
        if CoachVoice.watchGetsLine(mode: coachMode, statusBefore: before) { showCoachLine(day: day, index: index) }
    }

    /// The line to show now, or nil once a newer set is due.
    func visibleCoachLine(dueAlert: CivilDateTime?) -> String? {
        guard let coachLine, CoachVoice.watchShowsLine(shownAt: coachShownAt, dueAlert: dueAlert) else { return nil }
        return coachLine
    }

    func clearCoachLine() {
        coachLine = nil
        coachToken += 1
    }

    /// Item 19: the written line at once, then the iPhone's model line if it answers within the window.
    /// With VoiceOver on, the written line stays, so what was read is what stays on screen.
    private func showCoachLine(day: Int, index: Int) {
        guard coachMode != .off, let run = library.current else { return }
        let resolved = ScheduleEngine.resolve(run.input, now: CivilDateTime.local(Date()))
        guard let today = resolved.day(day) else { return }
        let finished = !today.sets.isEmpty && !today.sets.contains { $0.status == .upcoming }
        let reps = today.sets.first { $0.index == index }?.reps ?? today.reps
        guard let facts = CoachFacts.make(run: resolved, day: day, repsThisSet: reps, dayOneMax: run.input.dayOneMax,
                                          moment: finished ? .dayDone : .afterSet),
              let written = CoachVoice.writtenLine(mode: coachMode, facts: facts) else { return }
        coachToken += 1
        let token = coachToken
        coachLine = written
        coachShownAt = CivilDateTime.local(Date())
        guard !WKAccessibilityIsVoiceOverRunning(), WCSession.isSupported(),
              WCSession.default.activationState == .activated, WCSession.default.isReachable else { return }
        let sent = Date()
        let mode = coachMode
        // No error handler: if the iPhone can't answer, the written line simply stays.
        WCSession.default.sendMessage(CoachVoice.watchRequest(facts, mode: mode), replyHandler: { reply in
            let line = reply["line"] as? String
            let clear = reply["clear"] as? Bool ?? false
            Task { @MainActor in
                guard self.coachToken == token else { return }
                if clear {
                    self.coachMode = .off
                    self.clearCoachLine()
                } else if let line, CoachVoice.watchReplyInTime(elapsed: Date().timeIntervalSince(sent)) {
                    self.coachLine = line
                }
            }
        }, errorHandler: nil)
    }

    func snooze(day: Int, index: Int) {
        apply(kind: "snooze", day: day, index: index)
    }

    /// "Busy for 1 hour" from the wrist. The phone applies it and refills alerts.
    func busy() {
        WKInterfaceDevice.current().play(.click)
        apply(kind: "busy", day: 0, index: 0)
    }

    /// The Busy hour running now, from the last library the phone sent.
    func activeBusy() -> (until: CivilDateTime, skipped: Int)? {
        guard let run = library.current else { return nil }
        return ScheduleEngine.activeBusy(run.input, now: CivilDateTime.local(Date()))
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
        case "busy":
            run.input.events.append(.busy(at: now))
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
        if let raw = context["coach"] as? String {
            coachMode = CoachMode(rawValue: raw) ?? .off
        }
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
