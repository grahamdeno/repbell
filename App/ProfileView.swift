import RepBellEngine
import SwiftUI

/// Your numbers: what you've done and what it shows. Controls live in Settings.
struct ProfileView: View {
    @Environment(ProgramController.self) private var controller

    var body: some View {
        let model = controller.insightsModel()
        ScreenChrome(top: 8, scrolls: false) {
            VStack(alignment: .leading, spacing: 0) {
                Text(Copy.profileTitle)
                    .font(Chalk.display(48))
                    .textCase(.uppercase)
                    .accessibilityAddTraits(.isHeader)
                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {
                        if let run = model.run {
                            maxHero(run)
                            ProfileSection(model.runIsCurrent ? Copy.thisRun : Copy.lastRun) {
                                StatGrid(stats: model.runStats)
                            }
                            if model.runIsCurrent, !run.ahead.isEmpty {
                                ProfileSection(Copy.aheadTitle) {
                                    VStack(alignment: .leading, spacing: 14) {
                                        ForEach(run.ahead, id: \.self) { line in
                                            HStack(alignment: .top, spacing: 12) {
                                                Capsule().fill(Chalk.ink).frame(width: 4)
                                                Text(line)
                                                    .font(.body)
                                                    .foregroundStyle(Chalk.ink)
                                                    .fixedSize(horizontal: false, vertical: true)
                                            }
                                            .accessibilityElement(children: .combine)
                                        }
                                    }
                                }
                            }
                            if !run.observations.isEmpty {
                                ProfileSection(Copy.observations) {
                                    VStack(alignment: .leading, spacing: 14) {
                                        ForEach(Array(run.observations.enumerated()), id: \.offset) { _, note in
                                            ObservationRow(note: note) { controller.open(.settings) }
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
                if let gain = run.gainPercent, let through = run.gainThroughDay {
                    Text(Copy.gainLine(gain, throughDay: through))
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
