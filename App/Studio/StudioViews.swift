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
            .filter { $0.id != suggested?.id && !controller.workoutHeld($0.id) }
            .sorted { settings.missingGear($0).count < settings.missingGear($1).count }
        let held = library.sessions.filter { controller.workoutHeld($0.id) }
        ScreenChrome(top: 16, scrolls: false) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .center) {
                    StudioTopBar(title: StudioCopy.studio)
                    Button { controller.open(.workoutSettings) } label: {
                        Image(systemName: "gearshape")
                            .font(.title2)
                            .foregroundStyle(Chalk.inkMuted)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PressFade())
                    .accessibilityLabel(StudioCopy.settingsTitle)
                }
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        Button { controller.open(.fitMyTime) } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(StudioCopy.fitTitle)
                                        .font(Chalk.display(32))
                                        .textCase(.uppercase)
                                        .foregroundStyle(Chalk.ink)
                                    Text(StudioCopy.fitRowDetail)
                                        .font(.subheadline)
                                        .foregroundStyle(Chalk.inkMuted)
                                }
                                Spacer()
                                Image(systemName: "timer")
                                    .font(.title2)
                                    .foregroundStyle(Chalk.volt)
                            }
                            .padding(ChalkTokens.Space.s4)
                            .frame(minHeight: ChalkTokens.minimumTarget)
                            .outlinedCard()
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PressFade())
                        if let suggested {
                            VStack(alignment: .leading, spacing: 10) {
                                StudioEyebrow(StudioCopy.suggested)
                                Button { open(suggested) } label: {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(suggested.name)
                                            .font(Chalk.display(40))
                                            .textCase(.uppercase)
                                            .foregroundStyle(Chalk.onVolt)
                                        Text(StudioCopy.meta(suggested))
                                            .font(.subheadline.weight(.medium))
                                            .foregroundStyle(Chalk.onVolt.opacity(0.8))
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(20)
                                    .background(Chalk.volt)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(StudioCopy.groups, id: \.name) { group in
                                let members = others.filter { group.ids.contains($0.id) }
                                if !members.isEmpty {
                                    StudioEyebrow(group.name)
                                        .padding(.top, 16)
                                    ForEach(members) { session in
                                        Button { open(session) } label: { StudioRow(session: session) }
                                            .buttonStyle(.plain)
                                    }
                                }
                            }
                            let grouped = Set(StudioCopy.groups.flatMap(\.ids))
                            let rest = others.filter { !grouped.contains($0.id) }
                            if !rest.isEmpty {
                                StudioEyebrow(StudioCopy.allSessions)
                                    .padding(.top, 16)
                                ForEach(rest) { session in
                                    Button { open(session) } label: { StudioRow(session: session) }
                                        .buttonStyle(.plain)
                                }
                            }
                            if !held.isEmpty {
                                StudioEyebrow(StudioCopy.afterDay15)
                                    .padding(.top, 16)
                                Text(StudioCopy.heldReason)
                                    .font(.subheadline)
                                    .foregroundStyle(Chalk.inkMuted)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .padding(.top, 4)
                                ForEach(held) { session in
                                    Button { open(session) } label: { StudioRow(session: session, held: true) }
                                        .buttonStyle(PressFade())
                                }
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
        controller.open(.workoutSession(session.id))
    }
}

private struct StudioRow: View {
    var session: StudioSession
    var held = false
    private var settings: StudioSettings { StudioSettings.shared }

    var body: some View {
        let missing = held ? [] : settings.missingGear(session)
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(session.name)
                        .font(.headline)
                        .foregroundStyle(missing.isEmpty && !held ? Chalk.ink : Chalk.inkMuted)
                    if Features.payment && session.free {
                        Text(StudioCopy.free)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Chalk.volt)
                    }
                }
                Text(held ? StudioCopy.heldShort : (missing.isEmpty ? StudioCopy.meta(session) : StudioCopy.standIns(session)))
                    .font(.subheadline)
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

    var body: some View {
        // Fit my time rebuilds the session for "Another one"; the seed redraws this screen.
        StudioSessionContent(sessionID: sessionID)
            .id(sessionID == FitMyTime.sessionID ? controller.fitSeed : 0)
    }
}

private struct StudioSessionContent: View {
    @Environment(ProgramController.self) private var controller
    var sessionID: String
    @State private var askHold = false
    private var settings: StudioSettings { StudioSettings.shared }

    var body: some View {
        if let session = StudioLibrary.shared.session(sessionID) {
            ScreenChrome(top: 16, scrolls: false) {
                VStack(alignment: .leading, spacing: 0) {
                    StudioTopBar(title: session.name)
                    ScrollView {
                        VStack(alignment: .leading, spacing: 18) {
                            Text(StudioCopy.meta(session))
                                .font(.subheadline)
                                .foregroundStyle(Chalk.inkMuted)
                            if !settings.easyOn.isEmpty {
                                Text(StudioCopy.easyNote(settings.easyOn))
                                    .font(.subheadline)
                                    .foregroundStyle(Chalk.inkMuted)
                            }
                            VStack(spacing: 0) {
                                ForEach(Array(session.outline.enumerated()), id: \.offset) { index, item in
                                    let move = settings.resolve(item.id)
                                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                                        Text("\(index + 1)")
                                            .font(.subheadline.weight(.semibold).monospacedDigit())
                                            .foregroundStyle(Chalk.volt)
                                            .frame(width: 26, alignment: .leading)
                                        Text(move?.movement.name ?? item.id)
                                            .font(.body)
                                            .foregroundStyle(Chalk.ink)
                                        Spacer()
                                        Text(StudioCopy.clock(item.seconds))
                                            .font(.subheadline.monospacedDigit())
                                            .foregroundStyle(Chalk.inkMuted)
                                    }
                                    .padding(.vertical, 10)
                                    .overlay(alignment: .bottom) { Rectangle().fill(Chalk.line).frame(height: 1) }
                                }
                            }
                            if session.id == FitMyTime.sessionID {
                                SecondaryButton(title: StudioCopy.anotherOne, size: .compact) {
                                    controller.fitMyTime(minutes: session.minutes)
                                }
                            }
                            Text(StudioCopy.safety)
                                .font(.footnote)
                                .foregroundStyle(Chalk.inkMuted)
                        }
                        .padding(.vertical, 12)
                    }
                    .scrollIndicators(.hidden)
                    if controller.workoutHeld(session.id) {
                        Text(StudioCopy.heldReason)
                            .font(.subheadline)
                            .foregroundStyle(Chalk.inkMuted)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 12)
                    }
                    PrimaryButton(title: StudioCopy.start) {
                        if !Features.payment || session.free || controller.library.unlocked {
                            Haptics.play(.tap)
                            if controller.setsDuring(minutes: session.minutes) > 0 {
                                askHold = true
                            } else {
                                controller.screen = .studioPlayer(session.id)
                            }
                        } else {
                            controller.screen = .paywall
                        }
                    }
                    .padding(.top, 12)
                    .disabled(controller.workoutHeld(session.id))
                    .confirmationDialog(StudioCopy.holdTitle, isPresented: $askHold, titleVisibility: .visible) {
                        Button(StudioCopy.holdYes) {
                            controller.holdAlerts(minutes: session.minutes)
                            controller.screen = .studioPlayer(session.id)
                        }
                        Button(StudioCopy.holdNo) { controller.screen = .studioPlayer(session.id) }
                        Button(Copy.back, role: .cancel) {}
                    } message: {
                        Text(StudioCopy.holdBody(controller.setsDuring(minutes: session.minutes)))
                    }
                }
            }
        } else {
            ScreenChrome { Text(StudioCopy.missing).font(.body).foregroundStyle(Chalk.inkMuted) }
        }
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
                        .font(.subheadline)
                        .foregroundStyle(Chalk.inkMuted)
                    Spacer()
                    Button {
                        save(session)
                        controller.releaseAlerts()
                        controller.openWorkouts(session: session.id)
                    } label: {
                        Image(systemName: "xmark")
                            .font(.headline)
                            .foregroundStyle(Chalk.inkMuted)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(StudioCopy.end)
                }
                ProgressView(value: Double(index), total: Double(max(1, session.timeline.count)))
                    .tint(Chalk.volt)
                Text(StudioCopy.stepLabel(step))
                    .eyebrow(step.isMove ? Chalk.volt : Chalk.inkMuted)
                MascotStage(movement: move?.movement, sessionID: session.id, resting: !step.isMove)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
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
                                .font(.body)
                                .foregroundStyle(Chalk.inkMuted)
                        }
                        if let note = move.note {
                            Text(note)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(Chalk.volt)
                        }
                    }
                }
                Spacer(minLength: 0)
                HStack(alignment: .center) {
                    Text(StudioCopy.clock(remaining))
                        .font(Chalk.display(72))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .monospacedDigit()
                        .foregroundStyle(paused ? Chalk.inkMuted : Chalk.ink)
                    Spacer()
                    controlButton("backward.end.fill", label: StudioCopy.previous) { jump(session, by: -1) }
                        .disabled(index == 0)
                        .opacity(index == 0 ? 0.4 : 1)
                    controlButton(paused ? "play.fill" : "pause.fill", label: paused ? StudioCopy.resume : StudioCopy.pause) {
                        paused.toggle()
                        Haptics.play(.tap)
                    }
                    controlButton("forward.end.fill", label: StudioCopy.skip) { jump(session, by: 1) }
                }
                if let next = upcomingName(session) {
                    Text(StudioCopy.next(next))
                        .font(.subheadline)
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
        .accessibilityAction(named: StudioCopy.previous) { jump(session, by: -1) }
        .accessibilityAction(named: paused ? StudioCopy.resume : StudioCopy.pause) {
            paused.toggle()
            Haptics.play(.tap)
        }
        .accessibilityAction(named: StudioCopy.skip) { jump(session, by: 1) }
    }

    private func controlButton(_ symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.title2.weight(.semibold))
                .foregroundStyle(Chalk.ink)
                .frame(width: 64, height: 64)
                .overlay(Circle().stroke(Chalk.lineStrong, lineWidth: 1.5))
                .contentShape(Circle())
        }
        .buttonStyle(PressFade())
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
        controller.releaseAlerts()
        clearSaved()
        settings.record(session: session, seconds: elapsed)
        if settings.health {
            let seconds = elapsed
            Task { await StudioHealth.save(session: session, seconds: seconds) }
        }
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

/// The Workouts figure: the movement's animated line figure (figures.json). During a rest it shows the next
/// move's key position, still and dim. Falls back to a system figure if a clip is missing.
/// Coach media stays out until R-1 is met; the line figures are numbers, not media.
struct MascotStage: View {
    var movement: StudioMovement?
    var sessionID: String
    var resting: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20).fill(Chalk.surface)
            if let clip = Figures.clip(movement?.id) {
                FigureStage(clip: clip, tint: resting ? Chalk.inkFaint : Chalk.volt, still: resting)
                    .padding(10)
            } else {
                Image(systemName: symbol)
                    .font(.system(size: 110, weight: .regular))
                    .foregroundStyle(resting ? Chalk.inkFaint : Chalk.volt)
                    .symbolEffect(.pulse, isActive: !resting && !reduceMotion)
            }
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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var session: StudioSession
    var seconds: Int
    @State private var shown = false

    var body: some View {
        ZStack {
            Chalk.ground.ignoresSafeArea()
            VStack(spacing: 20) {
                Spacer()
                ZStack {
                    Circle().fill(Chalk.volt).frame(width: 180, height: 180).scaleEffect(shown || reduceMotion ? 1 : 0.2)
                    Image(systemName: "checkmark")
                        .font(.system(size: 88, weight: .black))
                        .foregroundStyle(Chalk.onVolt)
                        .scaleEffect(shown || reduceMotion ? 1 : 0.1)
                }
                .accessibilityHidden(true)
                Text(StudioCopy.sessionDone)
                    .font(Chalk.display(56))
                    .textCase(.uppercase)
                    .foregroundStyle(Chalk.ink)
                Text(StudioCopy.doneLine(session, seconds: seconds))
                    .font(.body)
                    .foregroundStyle(Chalk.inkMuted)
                Spacer()
                PrimaryButton(title: StudioCopy.backToToday) {
                    if controller.library.current == nil {
                        controller.openWorkouts()
                    } else {
                        controller.screen = .today
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .onAppear {
            withAnimation(reduceMotion ? .easeOut(duration: 0.2) : .spring(response: 0.45, dampingFraction: 0.6)) { shown = true }
        }
    }
}

// MARK: - Shared bits

/// Title row for Workouts screens. Back comes from the navigation bar, with swipe-back.
struct StudioTopBar: View {
    var title: String

    var body: some View {
        Text(title)
            .font(Chalk.display(34))
            .textCase(.uppercase)
            .foregroundStyle(Chalk.ink)
            .lineLimit(2)
            .minimumScaleFactor(0.7)
            .accessibilityAddTraits(.isHeader)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct StudioEyebrow: View {
    var text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text)
            .eyebrow(Chalk.inkMuted)
    }
}

/// Workouts settings, opened from the Workouts screen.
struct WorkoutSettingsView: View {
    var body: some View {
        ScreenChrome(top: 8, scrolls: false) {
            VStack(alignment: .leading, spacing: 12) {
                StudioTopBar(title: StudioCopy.settingsTitle)
                ScrollView {
                    StudioProfileSection()
                        .padding(.vertical, 12)
                }
                .scrollIndicators(.hidden)
            }
        }
    }
}

/// The Workouts settings controls: gear, Go easy on, Apple Health.
struct StudioProfileSection: View {
    @Bindable private var settings = StudioSettings.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("\(StudioCopy.iHave) · \(settings.gear.count)").font(.body.weight(.semibold)).foregroundStyle(Chalk.ink)
            ForEach(StudioSettings.allGear, id: \.self) { item in
                Toggle(StudioSettings.gearLabel(item), isOn: Binding(
                    get: { settings.gear.contains(item) },
                    set: { on in if on { settings.gear.insert(item) } else { settings.gear.remove(item) } }
                ))
                .tint(Chalk.volt)
                .foregroundStyle(Chalk.inkMuted)
            }
            Text(StudioCopy.goEasyOn).font(.body.weight(.semibold)).foregroundStyle(Chalk.ink)
            ForEach(StudioSettings.zones, id: \.self) { zone in
                Toggle(StudioSettings.zoneLabel(zone), isOn: Binding(
                    get: { settings.easyOn.contains(zone) },
                    set: { on in if on { settings.easyOn.insert(zone) } else { settings.easyOn.remove(zone) } }
                ))
                .tint(Chalk.volt)
                .foregroundStyle(Chalk.inkMuted)
            }
            if StudioHealth.available {
                Toggle(StudioCopy.saveToHealth, isOn: Binding(
                    get: { settings.health },
                    set: { on in
                        if on {
                            Task { settings.health = await StudioHealth.enable() }
                        } else {
                            settings.health = false
                        }
                    }
                ))
                .tint(Chalk.volt)
                .foregroundStyle(Chalk.inkMuted)
            }
            if !settings.log.isEmpty {
                Text(StudioCopy.sessionsDone(settings.log.count, minutes: settings.log.reduce(0) { $0 + $1.minutes }))
                    .font(.subheadline)
                    .foregroundStyle(Chalk.inkMuted)
            }
        }
    }
}

enum StudioCopy {
    static let studio = "Workouts"
    static let fitTitle = "Fit my time"
    static let fitRowDetail = "Pick the minutes you have. Rep Bell builds the session."
    static let fitHeadline = "How long\ndo you have?"
    static let anotherOne = "Another one"

    static func fitName(_ minutes: Int) -> String { "Fit my time · \(minutes) min" }

    static func fitFocusLine(_ focus: FitMyTime.Focus) -> String {
        switch focus {
        case .mobility: return "Today: mobility and stretching, easy on the push-up muscles."
        case .legs: return "Today: legs and back, so your push-up muscles rest."
        case .core: return "Today: core and easy cardio, so your push-up muscles rest."
        case .fullBody: return "Today: full body."
        }
    }
    static let settingsTitle = "Workouts settings"
    static let missing = "This session isn't in this version of Rep Bell."
    static let saveToHealth = "Save sessions to Apple Health"
    static let suggested = "Suggested today"
    static let allSessions = "More sessions"
    static let afterDay15 = "After Day 15"
    static let heldReason = "The program works best with no other upper-body training for the 14 days. These open after your final test."
    static let heldShort = "Opens after your final test"
    static let openWorkouts = "Workouts"

    /// How the Studio list is grouped. The suggested session always sits above these.
    static let groups: [(name: String, ids: [String])] = [
        ("Strength", ["upper", "lower-back", "shoulders-arms", "kettlebell", "grip-pull"]),
        ("Conditioning", ["jump", "strike", "easy-cardio"]),
        ("Core", ["core", "ab-finisher"]),
        ("Mobility", ["flow-45", "flow-90", "stretch", "balance"]),
    ]
    static let free = "Free"
    static let start = "Start"
    static let pause = "Pause"
    static let resume = "Resume"
    static let skip = "Skip"
    static let previous = "Previous"
    static let end = "End session"
    static let sessionDone = "Session done"
    static let backToToday = "Done"
    static let iHave = "My gear"
    static let goEasyOn = "Go easy on"
    static let wantMore = "Want more?"
    static let holdTitle = "Hold set alerts?"
    static let holdYes = "Hold until I finish"
    static let holdNo = "Keep them on"

    static func holdBody(_ count: Int) -> String {
        let sets = count == 1 ? "A set comes due" : "\(count) sets come due"
        return "\(sets) during this session. Held sets wait on Today until the next one, so you can do them after."
    }
    static let safety = "Stop if you feel sharp pain or dizziness. Every hard move has an easier version: swipe or tap Skip, or set Go easy on in Workouts settings."

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

/// Fit my time: one decision, the minutes. The focus follows the program day.
struct FitMyTimeView: View {
    @Environment(ProgramController.self) private var controller
    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        ScreenChrome(top: 8) {
            VStack(alignment: .leading, spacing: 20) {
                Text(StudioCopy.fitHeadline)
                    .font(Chalk.display(48))
                    .textCase(.uppercase)
                    .foregroundStyle(Chalk.ink)
                    .accessibilityAddTraits(.isHeader)
                Text(StudioCopy.fitFocusLine(controller.fitFocus()))
                    .font(.body)
                    .foregroundStyle(Chalk.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(FitMyTime.choices, id: \.self) { minutes in
                        Button { controller.fitMyTime(minutes: minutes) } label: {
                            VStack(spacing: 0) {
                                Text("\(minutes)")
                                    .font(Chalk.display(56))
                                    .foregroundStyle(Chalk.volt)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.5)
                                Text("min")
                                    .font(.subheadline)
                                    .foregroundStyle(Chalk.inkMuted)
                            }
                            .frame(maxWidth: .infinity, minHeight: 96)
                            .outlinedCard()
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PressFade())
                        .accessibilityLabel("\(minutes) minutes")
                    }
                }
            }
        }
    }
}
