import RepBellEngine
import SwiftUI

// MARK: - Studio list

struct StudioView: View {
    @Environment(ProgramController.self) private var controller
    private let library = StudioLibrary.shared
    private var settings: StudioSettings { StudioSettings.shared }

    var body: some View {
        let suggested = library.session(controller.studioSuggestion())
        let others = library.sessions
            .filter { $0.id != suggested?.id }
            .sorted { settings.missingGear($0).count < settings.missingGear($1).count }
        ScreenChrome(top: 16) {
            VStack(alignment: .leading, spacing: 0) {
                StudioTopBar(title: StudioCopy.studio) { controller.screen = controller.library.current == nil ? .promise : .today }
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        if let suggested {
                            VStack(alignment: .leading, spacing: 10) {
                                StudioEyebrow(StudioCopy.suggested)
                                Button { open(suggested) } label: {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(suggested.name)
                                            .font(Chalk.display(40))
                                            .textCase(.uppercase)
                                            .foregroundStyle(Chalk.onAccent)
                                        Text(StudioCopy.meta(suggested))
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundStyle(Chalk.onAccent.opacity(0.8))
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(20)
                                    .background(Chalk.accent)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        VStack(alignment: .leading, spacing: 0) {
                            StudioEyebrow(StudioCopy.allSessions)
                            ForEach(others) { session in
                                Button { open(session) } label: { StudioRow(session: session) }
                                    .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.vertical, 12)
                }
                .scrollIndicators(.hidden)
            }
        }
    }

    private func open(_ session: StudioSession) {
        Haptics.play(.tap)
        controller.screen = .studioSession(session.id)
    }
}

private struct StudioRow: View {
    var session: StudioSession
    private var settings: StudioSettings { StudioSettings.shared }

    var body: some View {
        let missing = settings.missingGear(session)
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(session.name)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(missing.isEmpty ? Chalk.ink : Chalk.inkMuted)
                    if session.free {
                        Text(StudioCopy.free)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Chalk.accent)
                    }
                }
                Text(missing.isEmpty ? StudioCopy.meta(session) : StudioCopy.standIns(session))
                    .font(.system(size: 14))
                    .foregroundStyle(Chalk.inkMuted)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(Chalk.inkFaint)
        }
        .padding(.vertical, 14)
        .overlay(alignment: .bottom) { Rectangle().fill(Chalk.line).frame(height: 1) }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Session detail

struct StudioSessionView: View {
    @Environment(ProgramController.self) private var controller
    var sessionID: String
    private var settings: StudioSettings { StudioSettings.shared }

    var body: some View {
        if let session = StudioLibrary.shared.session(sessionID) {
            ScreenChrome(top: 16) {
                VStack(alignment: .leading, spacing: 0) {
                    StudioTopBar(title: session.name) { controller.screen = .studio }
                    ScrollView {
                        VStack(alignment: .leading, spacing: 18) {
                            Text(StudioCopy.meta(session))
                                .font(.system(size: 15))
                                .foregroundStyle(Chalk.inkSoft)
                            MascotPicker()
                            if !settings.easyOn.isEmpty {
                                Text(StudioCopy.easyNote(settings.easyOn))
                                    .font(.system(size: 14))
                                    .foregroundStyle(Chalk.inkMuted)
                            }
                            VStack(spacing: 0) {
                                ForEach(Array(session.outline.enumerated()), id: \.offset) { index, item in
                                    let move = settings.resolve(item.id)
                                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                                        Text("\(index + 1)")
                                            .font(.system(size: 14, weight: .semibold).monospacedDigit())
                                            .foregroundStyle(Chalk.accent)
                                            .frame(width: 26, alignment: .leading)
                                        Text(move?.movement.name ?? item.id)
                                            .font(.system(size: 16))
                                            .foregroundStyle(Chalk.ink)
                                        Spacer()
                                        Text(StudioCopy.clock(item.seconds))
                                            .font(.system(size: 15).monospacedDigit())
                                            .foregroundStyle(Chalk.inkMuted)
                                    }
                                    .padding(.vertical, 10)
                                    .overlay(alignment: .bottom) { Rectangle().fill(Chalk.line).frame(height: 1) }
                                }
                            }
                            Text(StudioCopy.safety)
                                .font(.system(size: 13))
                                .foregroundStyle(Chalk.inkMuted)
                        }
                        .padding(.vertical, 12)
                    }
                    .scrollIndicators(.hidden)
                    PrimaryButton(title: StudioCopy.start) {
                        if session.free || controller.library.unlocked {
                            Haptics.play(.tap)
                            controller.screen = .studioPlayer(session.id)
                        } else {
                            controller.screen = .paywall
                        }
                    }
                    .padding(.top, 12)
                }
            }
        } else {
            ScreenChrome { SecondaryButton(title: Copy.back) { controller.screen = .studio } }
        }
    }
}

struct MascotPicker: View {
    @Bindable private var settings = StudioSettings.shared

    var body: some View {
        Picker(StudioCopy.mascot, selection: $settings.mascot) {
            Text(StudioCopy.him).tag("him")
            Text(StudioCopy.her).tag("her")
        }
        .pickerStyle(.segmented)
        .frame(maxWidth: 220)
    }
}

// MARK: - Player

struct StudioPlayerView: View {
    @Environment(ProgramController.self) private var controller
    var sessionID: String

    @State private var index = 0
    @State private var remaining = 0
    @State private var paused = false
    @State private var elapsed = 0
    @State private var finished = false

    private var settings: StudioSettings { StudioSettings.shared }

    var body: some View {
        if let session = StudioLibrary.shared.session(sessionID) {
            Group {
                if finished {
                    StudioDoneView(session: session, seconds: elapsed)
                } else {
                    player(session)
                }
            }
            .onAppear {
                UIApplication.shared.isIdleTimerDisabled = true
                restore(session)
            }
            .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
            .task(id: sessionID) { await run(session) }
        }
    }

    @ViewBuilder
    private func player(_ session: StudioSession) -> some View {
        let step = session.timeline[min(index, session.timeline.count - 1)]
        let showID = step.isMove ? step.id : step.next
        let move = showID.flatMap { settings.resolve($0) }
        let movesBefore = session.timeline.prefix(index + 1).filter(\.isMove).count
        let movesTotal = session.timeline.filter(\.isMove).count
        ScreenChrome(top: 16) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("\(session.name) · \(movesBefore) of \(movesTotal)")
                        .font(.system(size: 14))
                        .foregroundStyle(Chalk.inkMuted)
                    Spacer()
                    Button {
                        save(session)
                        controller.screen = .studioSession(session.id)
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Chalk.inkSoft)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(StudioCopy.end)
                }
                ProgressView(value: Double(index), total: Double(max(1, session.timeline.count)))
                    .tint(Chalk.accent)
                Text(StudioCopy.stepLabel(step))
                    .font(Chalk.display(22, weight: .bold))
                    .tracking(0.8)
                    .textCase(.uppercase)
                    .foregroundStyle(step.isMove ? Chalk.accent : Chalk.inkMuted)
                MascotStage(movement: move?.movement, sessionID: session.id, resting: !step.isMove)
                    .frame(maxWidth: .infinity)
                    .frame(height: 220)
                Text(move?.movement.name ?? "")
                    .font(Chalk.display(40))
                    .textCase(.uppercase)
                    .foregroundStyle(Chalk.ink)
                    .lineLimit(2)
                    .minimumScaleFactor(0.6)
                if let move {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(move.cues, id: \.self) { cue in
                            Text(cue)
                                .font(.system(size: 16))
                                .foregroundStyle(Chalk.inkSoft)
                        }
                        if let note = move.note {
                            Text(note)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Chalk.accent)
                        }
                    }
                }
                Spacer(minLength: 0)
                HStack(alignment: .center) {
                    Text(StudioCopy.clock(remaining))
                        .font(Chalk.display(72))
                        .monospacedDigit()
                        .foregroundStyle(paused ? Chalk.inkMuted : Chalk.ink)
                    Spacer()
                    controlButton(paused ? "play.fill" : "pause.fill", label: paused ? StudioCopy.resume : StudioCopy.pause) {
                        paused.toggle()
                        Haptics.play(.tap)
                    }
                    controlButton("forward.end.fill", label: StudioCopy.skip) { jump(session, by: 1) }
                }
                if let next = upcomingName(session) {
                    Text(StudioCopy.next(next))
                        .font(.system(size: 14))
                        .foregroundStyle(Chalk.inkMuted)
                }
            }
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 40).onEnded { value in
                if value.translation.width < -60 { jump(session, by: 1) }
                if value.translation.width > 60 { jump(session, by: -1) }
            }
        )
    }

    private func controlButton(_ symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(Chalk.ink)
                .frame(width: 64, height: 64)
                .overlay(Circle().stroke(Chalk.lineStrong, lineWidth: 1.5))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    private func upcomingName(_ session: StudioSession) -> String? {
        let after = session.timeline.dropFirst(index + 1)
        guard let next = after.first(where: \.isMove), let move = settings.resolve(next.id ?? "") else { return nil }
        if let side = next.side { return "\(move.movement.name), \(side)" }
        return move.movement.name
    }

    private func jump(_ session: StudioSession, by delta: Int) {
        let target = index + delta
        guard target >= 0 else { return }
        Haptics.play(.tap)
        if target >= session.timeline.count {
            complete(session)
            return
        }
        index = target
        remaining = session.timeline[target].seconds
    }

    private func run(_ session: StudioSession) async {
        guard !session.timeline.isEmpty else { return }
        if remaining == 0 { remaining = session.timeline[index].seconds }
        while !Task.isCancelled && !finished {
            try? await Task.sleep(for: .seconds(1))
            guard !paused, !finished else { continue }
            elapsed += 1
            remaining -= 1
            if remaining == 3 && session.timeline[index].isMove == false {
                Haptics.play(.tap)
            }
            if remaining <= 0 {
                let target = index + 1
                if target >= session.timeline.count {
                    complete(session)
                } else {
                    index = target
                    remaining = session.timeline[target].seconds
                    Haptics.play(session.timeline[target].isMove ? .setDone : .tap)
                }
            }
        }
    }

    private func complete(_ session: StudioSession) {
        finished = true
        clearSaved()
        settings.record(session: session, seconds: elapsed)
        Haptics.play(.dayComplete)
    }

    // Resume within 30 minutes if the person leaves mid-session.
    private func save(_ session: StudioSession) {
        let state: [String: Any] = ["id": session.id, "index": index, "remaining": remaining, "elapsed": elapsed, "at": Date().timeIntervalSince1970]
        UserDefaults.standard.set(state, forKey: "studio.resume")
    }

    private func restore(_ session: StudioSession) {
        guard let state = UserDefaults.standard.dictionary(forKey: "studio.resume"),
              state["id"] as? String == session.id,
              let at = state["at"] as? Double,
              Date().timeIntervalSince1970 - at < 30 * 60,
              let savedIndex = state["index"] as? Int, savedIndex < session.timeline.count else {
            index = 0
            remaining = session.timeline.first?.seconds ?? 0
            return
        }
        index = savedIndex
        remaining = state["remaining"] as? Int ?? session.timeline[savedIndex].seconds
        elapsed = state["elapsed"] as? Int ?? 0
    }

    private func clearSaved() {
        UserDefaults.standard.removeObject(forKey: "studio.resume")
    }
}

/// Placeholder stage until the puppet art lands: a large figure symbol chosen by session.
struct MascotStage: View {
    var movement: StudioMovement?
    var sessionID: String
    var resting: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20).fill(Chalk.surface)
            Image(systemName: symbol)
                .font(.system(size: 110, weight: .regular))
                .foregroundStyle(resting ? Chalk.inkFaint : Chalk.accent)
                .symbolEffect(.pulse, isActive: !resting)
        }
        .accessibilityHidden(true)
    }

    private var symbol: String {
        if resting { return "figure.stand" }
        switch sessionID {
        case "flow-45", "flow-90", "stretch": return "figure.mind.and.body"
        case "strike": return "figure.boxing"
        case "jump": return "figure.jumprope"
        case "core", "ab-finisher": return "figure.core.training"
        case "easy-cardio": return "figure.walk"
        default: return "figure.strengthtraining.functional"
        }
    }
}

// MARK: - Done

struct StudioDoneView: View {
    @Environment(ProgramController.self) private var controller
    var session: StudioSession
    var seconds: Int
    @State private var shown = false

    var body: some View {
        ZStack {
            Chalk.ground.ignoresSafeArea()
            VStack(spacing: 20) {
                Spacer()
                ZStack {
                    Circle().fill(Chalk.accent).frame(width: 180, height: 180).scaleEffect(shown ? 1 : 0.2)
                    Image(systemName: "checkmark")
                        .font(.system(size: 88, weight: .black))
                        .foregroundStyle(Chalk.onAccent)
                        .scaleEffect(shown ? 1 : 0.1)
                }
                Text(StudioCopy.sessionDone)
                    .font(Chalk.display(56))
                    .textCase(.uppercase)
                    .foregroundStyle(Chalk.ink)
                Text(StudioCopy.doneLine(session, seconds: seconds))
                    .font(.system(size: 17))
                    .foregroundStyle(Chalk.inkSoft)
                Spacer()
                PrimaryButton(title: StudioCopy.backToToday) {
                    controller.screen = controller.library.current == nil ? .studio : .today
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .onAppear { withAnimation(.spring(response: 0.45, dampingFraction: 0.6)) { shown = true } }
    }
}

// MARK: - Shared bits

struct StudioTopBar: View {
    var title: String
    var back: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Button(action: back) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Chalk.inkSoft)
                    .frame(width: 44, height: 44, alignment: .leading)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Copy.back)
            Text(title)
                .font(Chalk.display(34))
                .textCase(.uppercase)
                .foregroundStyle(Chalk.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Spacer()
        }
    }
}

struct StudioEyebrow: View {
    var text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text)
            .font(Chalk.display(18, weight: .bold))
            .tracking(0.8)
            .textCase(.uppercase)
            .foregroundStyle(Chalk.inkMuted)
    }
}

/// Studio settings shown inside Profile.
struct StudioProfileSection: View {
    @Bindable private var settings = StudioSettings.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(StudioCopy.studio)
                .font(Chalk.display(22, weight: .bold))
                .tracking(0.8)
                .textCase(.uppercase)
                .foregroundStyle(Chalk.inkMuted)
            HStack {
                Text(StudioCopy.mascot).font(.system(size: 16)).foregroundStyle(Chalk.inkSoft)
                Spacer()
                MascotPicker()
            }
            Text(StudioCopy.iHave).font(.system(size: 16, weight: .semibold)).foregroundStyle(Chalk.ink)
            ForEach(StudioSettings.allGear, id: \.self) { item in
                Toggle(StudioSettings.gearLabel(item), isOn: Binding(
                    get: { settings.gear.contains(item) },
                    set: { on in if on { settings.gear.insert(item) } else { settings.gear.remove(item) } }
                ))
                .tint(Chalk.accent)
                .foregroundStyle(Chalk.inkSoft)
            }
            Text(StudioCopy.goEasyOn).font(.system(size: 16, weight: .semibold)).foregroundStyle(Chalk.ink)
            ForEach(StudioSettings.zones, id: \.self) { zone in
                Toggle(StudioSettings.zoneLabel(zone), isOn: Binding(
                    get: { settings.easyOn.contains(zone) },
                    set: { on in if on { settings.easyOn.insert(zone) } else { settings.easyOn.remove(zone) } }
                ))
                .tint(Chalk.accent)
                .foregroundStyle(Chalk.inkSoft)
            }
            if !settings.log.isEmpty {
                Text(StudioCopy.sessionsDone(settings.log.count, minutes: settings.log.reduce(0) { $0 + $1.minutes }))
                    .font(.system(size: 14))
                    .foregroundStyle(Chalk.inkMuted)
            }
        }
    }
}

enum StudioCopy {
    static let studio = "Studio"
    static let suggested = "Suggested today"
    static let allSessions = "All sessions"
    static let free = "Free"
    static let start = "Start"
    static let mascot = "Coach"
    static let him = "Him"
    static let her = "Her"
    static let pause = "Pause"
    static let resume = "Resume"
    static let skip = "Skip"
    static let end = "End session"
    static let sessionDone = "Session done"
    static let backToToday = "Done"
    static let iHave = "I have"
    static let goEasyOn = "Go easy on"
    static let wantMore = "Want more?"
    static let safety = "Stop if you feel sharp pain or dizziness. Every hard move has an easier version: swipe or tap Skip, or set Go easy on in Profile."

    static func meta(_ s: StudioSession) -> String {
        let gear = s.gear.filter { $0 != "mat" }.map { StudioSettings.gearLabel($0).lowercased() }
        let base = "\(s.minutes) min"
        return gear.isEmpty ? base : "\(base) · \(gear.joined(separator: ", "))"
    }

    static func standIns(_ s: StudioSession) -> String {
        "\(s.minutes) min · stand-ins for gear you don't have"
    }

    static func easyNote(_ zones: Set<String>) -> String {
        let names = StudioSettings.zones.filter { zones.contains($0) }.map { StudioSettings.zoneLabel($0).lowercased() }
        return "Going easy on your \(names.joined(separator: ", ")). Poses adjust automatically."
    }

    static func clock(_ seconds: Int) -> String {
        let s = max(0, seconds)
        return String(format: "%d:%02d", s / 60, s % 60)
    }

    static func stepLabel(_ step: StudioStep) -> String {
        switch step.type {
        case "getReady": return "Get ready"
        case "transition": return "Get set"
        case "switch": return "Switch sides"
        case "roundRest": return "Rest, next round"
        case "rest": return "Rest"
        default:
            if step.role == "recovery" { return "Easy walk" }
            if step.pace == "easy" { return "Easy pace" }
            if let side = step.side { return side == "left" ? "Left side" : "Right side" }
            return "Go"
        }
    }

    static func next(_ name: String) -> String { "Next: \(name)" }

    static func doneLine(_ s: StudioSession, seconds: Int) -> String {
        "\(s.name) · \(max(1, seconds / 60)) min"
    }

    static func sessionsDone(_ count: Int, minutes: Int) -> String {
        count == 1 ? "1 session done · \(minutes) min" : "\(count) sessions done · \(minutes) min"
    }
}
