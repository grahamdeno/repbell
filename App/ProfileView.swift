import RepBellEngine
import SwiftUI

/// Your numbers: what you've done and what it shows. Controls live in Settings.
struct ProfileView: View {
    @Environment(ProgramController.self) private var controller

    var body: some View {
        let model = controller.insightsModel()
        ScreenChrome(top: 28, scrolls: false) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .firstTextBaseline) {
                    Text(Copy.profileTitle)
                        .font(Chalk.display(48))
                        .textCase(.uppercase)
                    Spacer()
                    Button { controller.screen = .settings } label: {
                        Image(systemName: "gearshape")
                            .font(.title3)
                            .foregroundStyle(Chalk.inkSoft)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Copy.settingsTitle)
                }
                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {
                        if let run = model.run {
                            maxHero(run)
                            ProfileSection(model.runIsCurrent ? Copy.thisRun : Copy.lastRun) {
                                StatGrid(stats: model.runStats)
                            }
                            if !run.observations.isEmpty {
                                ProfileSection(Copy.observations) {
                                    VStack(alignment: .leading, spacing: 14) {
                                        ForEach(Array(run.observations.enumerated()), id: \.offset) { _, note in
                                            ObservationRow(note: note) { controller.screen = .settings }
                                        }
                                    }
                                }
                            }
                        } else {
                            Text(Copy.insightsEmpty)
                                .font(.body)
                                .foregroundStyle(Chalk.inkSoft)
                        }
                        if !model.allTime.isEmpty {
                            ProfileSection(Copy.allTime) { StatGrid(stats: model.allTime) }
                        }
                        if StudioFeature.enabled, !model.studio.isEmpty {
                            ProfileSection(StudioCopy.studio) { StatGrid(stats: model.studio) }
                        }
                        if !model.record.isEmpty {
                            ProfileSection(Copy.yourRecord) { ProfileRows(items: model.record) }
                        }
                    }
                    .padding(.vertical, 16)
                }
                .scrollIndicators(.hidden)
                SecondaryButton(title: Copy.back) {
                    controller.screen = controller.library.current == nil ? .promise : .today
                }
                .padding(.top, 12)
            }
        }
    }

    @ViewBuilder
    private func maxHero(_ run: RunInsights) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(Copy.yourMax)
                .eyebrow(Chalk.inkMuted)
            if run.maxes.isEmpty {
                Text(Copy.testOnDayOne)
                    .font(.body)
                    .foregroundStyle(Chalk.inkSoft)
            } else {
                HStack(alignment: .lastTextBaseline, spacing: 10) {
                    ForEach(Array(run.maxes.enumerated()), id: \.offset) { index, max in
                        if index > 0 {
                            Image(systemName: "arrow.right")
                                .font(.headline)
                                .foregroundStyle(Chalk.inkFaint)
                        }
                        VStack(alignment: .leading, spacing: 0) {
                            Text("\(max.reps)")
                                .font(Chalk.display(index == run.maxes.count - 1 ? 72 : 44))
                                .foregroundStyle(index == run.maxes.count - 1 ? Chalk.accent : Chalk.ink)
                            Text("Day \(max.day)")
                                .font(.footnote)
                                .foregroundStyle(Chalk.inkMuted)
                        }
                    }
                }
                if let gain = run.gainPercent {
                    Text(gain >= 0 ? "Up \(gain)%" : "Down \(-gain)%")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(gain >= 0 ? Chalk.accent : Chalk.inkSoft)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }
}

struct ProfileStat: Identifiable, Equatable {
    var id: String { label }
    var label: String
    var value: String
}

struct StatGrid: View {
    var stats: [ProfileStat]

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            ForEach(stats) { stat in
                VStack(alignment: .leading, spacing: 4) {
                    Text(stat.value)
                        .font(Chalk.display(30))
                        .foregroundStyle(Chalk.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    Text(stat.label)
                        .font(.footnote)
                        .foregroundStyle(Chalk.inkMuted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(Chalk.surface)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .accessibilityElement(children: .combine)
            }
        }
    }
}

private struct ObservationRow: View {
    var note: RunInsights.Observation
    var openSchedule: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Capsule().fill(Chalk.accent).frame(width: 4)
            VStack(alignment: .leading, spacing: 6) {
                Text(note.text)
                    .font(.body)
                    .foregroundStyle(Chalk.ink)
                    .fixedSize(horizontal: false, vertical: true)
                if note.link == .schedule {
                    TextLink(title: Copy.changeSchedule, action: openSchedule)
                        .padding(.leading, -ChalkTokens.Space.s3)
                }
            }
        }
    }
}

struct ProfileSection<Content: View>: View {
    var title: String
    var content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .eyebrow(Chalk.inkMuted)
            content
        }
    }
}

struct ProfileRows: View {
    var items: [ProfileRow]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(items) { item in ProfileRowView(item: item) }
        }
    }
}

struct ProfileRowView: View {
    var item: ProfileRow

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(item.label)
                .font(.body)
                .foregroundStyle(Chalk.inkSoft)
            Spacer(minLength: 12)
            Text(item.value)
                .font(.body.weight(.semibold))
                .foregroundStyle(Chalk.ink)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 12)
        .overlay(alignment: .bottom) { Rectangle().fill(Chalk.line).frame(height: 1) }
        .accessibilityElement(children: .combine)
    }
}

struct BusySheet: View {
    @Environment(ProgramController.self) private var controller

    var body: some View {
        let skipped = controller.setsInNextHour()
        let resume = Copy.clock(controller.busyUntil())
        VStack(alignment: .leading, spacing: 16) {
            Text(Copy.busySheetTitle)
                .font(Chalk.display(34))
                .textCase(.uppercase)
                .foregroundStyle(Chalk.ink)
            if skipped.isEmpty {
                Text(Copy.busyNothingSkipped(resume: resume))
                    .font(.body)
                    .foregroundStyle(Chalk.inkSoft)
            } else {
                Text(Copy.busySkipIntro(count: skipped.count))
                    .font(.body)
                    .foregroundStyle(Chalk.inkSoft)
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(skipped) { set in
                        Text(Copy.skippedRow(time: set.alert.map { Copy.clock($0) } ?? "", reps: set.reps))
                            .font(.body.weight(.semibold))
                            .foregroundStyle(Chalk.ink)
                    }
                }
                Text(Copy.busyResume(resume))
                    .font(.subheadline)
                    .foregroundStyle(Chalk.inkMuted)
            }
            Spacer(minLength: 8)
            PrimaryButton(title: Copy.busyPause) { controller.confirmBusy() }
            SecondaryButton(title: Copy.back, height: 56) { controller.showBusyConfirm = false }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Chalk.ground.ignoresSafeArea())
        .presentationDetents([.medium, .large])
        .presentationBackground(Chalk.ground)
    }
}
