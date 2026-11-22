import RepBellEngine
import SwiftUI

struct TodayView: View {
    @Environment(ProgramController.self) private var controller
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.periodic(from: .now, by: 15)) { _ in
            let model = controller.todaySnapshot()
            // A set is due: the bell-ring flood takes the whole screen until Done, In 10 min or Busy.
            if let due = controller.dueSet(), controller.celebration == nil, controller.deskStretch == nil, !model.marks.isEmpty {
                BellFloodView(set: due, total: model.marks.count, showBusy: model.showBusy && controller.activeBusy() == nil)
                    .transition(.opacity)
            } else {
                content(model)
                    .transition(.opacity)
            }
        }
        .animation(reduceMotion ? nil : .easeOut(duration: 0.35), value: controller.dueSet().map { "\($0.day).\($0.index)" })
        .overlay {
            if let celebration = controller.celebration {
                CelebrationView(celebration: celebration) { controller.celebration = nil }
                    .transition(.opacity)
            } else if let stretch = controller.deskStretch {
                DeskStretchView(stretch: stretch) { controller.deskStretch = nil }
                    .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.2), value: controller.celebration)
        .animation(.easeOut(duration: 0.2), value: controller.deskStretch)
    }

    @ViewBuilder
    private var headerButtons: some View {
        if StudioFeature.enabled {
            headerButton("dumbbell", label: StudioCopy.studio) { controller.open(.workouts) }
        }
        headerButton("chart.line.uptrend.xyaxis", label: Copy.profileLabel) { controller.open(.progress) }
        headerButton("gearshape", label: Copy.settingsTitle) { controller.open(.settings) }
    }

    private func headerButton(_ symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.title2)
                .foregroundStyle(Chalk.inkMuted)
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(PressFade())
        .accessibilityLabel(label)
    }

    @ViewBuilder
    private func content(_ model: TodaySnapshot) -> some View {
        // The main action stays on screen on small phones: the footer is pinned and the rest scrolls.
        // At accessibility text sizes it scrolls with the page instead, so it never covers half the screen.
        let pinned = !typeSize.isAccessibilitySize
        ScreenChrome {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 12) {
                    // At accessibility sizes the heading gets its own line, so the buttons never cover it.
                    if typeSize.isAccessibilitySize {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(model.eyebrow)
                                .eyebrow()
                            HStack(spacing: 8) { headerButtons }
                        }
                    } else {
                        HStack(alignment: .firstTextBaseline) {
                            Text(model.eyebrow)
                                .eyebrow()
                            Spacer()
                            headerButtons
                        }
                    }
                    if !model.bars.isEmpty {
                        DayBars(marks: model.bars)
                            .accessibilityLabel(model.eyebrow)
                    }
                }
                hero(model)
                if let fallback = model.fallback {
                    Text(fallback)
                        .font(.subheadline)
                        .foregroundStyle(Chalk.inkMuted)
                }
                if let title = model.tallyTitle, let detail = model.tallyDetail {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(title)
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                            Text(detail)
                                .font(.subheadline)
                                .foregroundStyle(Chalk.inkMuted)
                        }
                        SetTally(marks: model.marks)
                        if let soFar = model.soFar {
                            Text(soFar)
                                .font(.subheadline)
                                .foregroundStyle(Chalk.inkMuted)
                        }
                    }
                }
                if !pinned {
                    Spacer(minLength: 12)
                    footer(model)
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if pinned {
                footer(model)
                    .padding(.horizontal, ChalkTokens.Space.s6)
                    .padding(.top, ChalkTokens.Space.s3)
                    .padding(.bottom, ChalkTokens.Space.s2)
                    .background(Chalk.ground)
            }
        }
    }

    @ViewBuilder
    private func hero(_ model: TodaySnapshot) -> some View {
        switch model.hero {
        case .waiting(let eyebrow, let time, let title, let detail):
            VStack(alignment: .leading, spacing: 8) {
                Text(eyebrow)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Chalk.inkMuted)
                Text(time)
                    .font(Chalk.display(150))
                    .foregroundStyle(Chalk.amber)
                    .lineLimit(1)
                    .minimumScaleFactor(0.3)
                Text(title)
                    .font(Chalk.display(44))
                    .textCase(.uppercase)
                Text(detail)
                    .font(.body)
                    .foregroundStyle(Chalk.inkMuted)
            }
        case .test:
            VStack(alignment: .leading, spacing: 8) {
                Text(Copy.testAlarm)
                    .font(Chalk.display(44))
                    .textCase(.uppercase)
                    .foregroundStyle(Chalk.ink)
                Text(Copy.testHeroBody)
                    .font(.body)
                    .foregroundStyle(Chalk.inkMuted)
            }
        case .next(let time, let reps, let line):
            VStack(alignment: .leading, spacing: 4) {
                Text(time)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Chalk.inkMuted)
                Text("\(reps)")
                    .font(Chalk.display(160))
                    .foregroundStyle(Chalk.amber)
                    .lineLimit(1)
                    .minimumScaleFactor(0.25)
                Text(Copy.keepHyphenatedWords(line))
                    .font(Chalk.display(28, weight: .bold))
                    .tracking(0.6)
                    .textCase(.uppercase)
            }
        case .finished(let line):
            VStack(alignment: .leading, spacing: 20) {
                Text(Copy.keepHyphenatedWords(line))
                    .font(Chalk.display(40))
                    .textCase(.uppercase)
                    .foregroundStyle(Chalk.ink)
                if StudioFeature.enabled, let suggestion = StudioLibrary.shared.session(controller.studioSuggestion()) {
                    Button { controller.open(.workoutSession(suggestion.id)) } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(StudioCopy.wantMore)
                                .font(.subheadline)
                                .foregroundStyle(Chalk.inkMuted)
                            HStack {
                                Text("\(suggestion.name) · \(suggestion.minutes) min")
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(Chalk.ink)
                                Spacer()
                                Image(systemName: "arrow.right")
                                    .foregroundStyle(Chalk.amber)
                            }
                        }
                        .padding(16)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Chalk.lineStrong, lineWidth: 1.5))
                    }
                    .buttonStyle(.plain)
                }
            }
        case .paused(let day):
            VStack(alignment: .leading, spacing: 8) {
                Text(Copy.paused)
                    .font(Chalk.display(48))
                    .textCase(.uppercase)
                    .foregroundStyle(Chalk.amber)
                Text(Copy.pauseDetail(day: day))
                    .font(.body)
                    .foregroundStyle(Chalk.inkMuted)
            }
        }
    }

    @ViewBuilder
    private func footer(_ model: TodaySnapshot) -> some View {
        VStack(spacing: 8) {
            switch model.hero {
            case .test(let day):
                PrimaryButton(title: Copy.startTest) { controller.openCounter(day: day, preserve: false) }
            case .paused:
                PrimaryButton(title: Copy.resume) { controller.resume() }
            default:
                if let due = controller.dueSet() {
                    HStack(spacing: ChalkTokens.Space.s3) {
                        PrimaryButton(title: Copy.doneSet(due.reps)) { controller.logDone(day: due.day, index: due.index, celebrate: true) }
                            .layoutPriority(1)
                        SecondaryButton(title: Copy.inTen) { controller.logSnooze(day: due.day, index: due.index) }
                    }
                }
                if let busy = controller.activeBusy() {
                    HStack {
                        Text(Copy.busyStrip(until: busy.until, skipped: busy.skipped))
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Chalk.inkMuted)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: ChalkTokens.Space.s2)
                        TextLink(title: Copy.undo) { controller.undoBusy() }
                    }
                    .padding(.leading, ChalkTokens.Space.s4)
                    .outlinedCard(radius: ChalkTokens.Radius.button, color: Chalk.line)
                    .accessibilityElement(children: .contain)
                } else if model.showBusy {
                    SecondaryButton(title: Copy.busy, height: 56) { controller.confirmBusy() }
                }
            }
            if case .paused = model.hero {
                EmptyView()
            } else if controller.library.current?.ended != true {
                TextLink(title: Copy.somethingHurts) { controller.screen = .hurts }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

private struct SetTally: View {
    var marks: [SetMark]
    @Environment(\.colorSchemeContrast) private var contrast
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 11)

    var body: some View {
        LazyVGrid(columns: columns, alignment: .center, spacing: 6) {
            ForEach(Array(marks.enumerated()), id: \.offset) { _, mark in
                markView(mark)
                    .frame(height: 30)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Copy.todaysSets)
        .accessibilityValue(Copy.tallySpoken(marks: marks.map(\.spoken)))
    }

    @ViewBuilder
    private func markView(_ mark: SetMark) -> some View {
        let radius = ChalkTokens.Radius.set
        switch mark {
        case .done:
            RoundedRectangle(cornerRadius: radius).fill(Chalk.ink).frame(height: 22)
        case .current:
            // Taller, with a ring, so the current set never relies on color alone.
            RoundedRectangle(cornerRadius: radius)
                .fill(Chalk.amber)
                .frame(height: 30)
                .overlay(RoundedRectangle(cornerRadius: radius).stroke(Chalk.ink, lineWidth: 2))
        case .upcoming:
            RoundedRectangle(cornerRadius: radius)
                .stroke(Chalk.markOutline(contrast), lineWidth: 1.5)
                .frame(height: 22)
        case .missed:
            RoundedRectangle(cornerRadius: radius)
                .stroke(Chalk.markOutline(contrast), style: StrokeStyle(lineWidth: 1.5, dash: [3, 2]))
                .frame(height: 22)
        }
    }
}

extension SetMark {
    var spoken: Copy.SpokenMark {
        switch self {
        case .done: .done
        case .missed: .missed
        case .current: .current
        case .upcoming: .upcoming
        }
    }
}
