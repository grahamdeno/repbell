import ActivityKit
import AlarmKit
import RepBellEngine
import SwiftUI
import WidgetKit

@main
struct RepBellWidgets: WidgetBundle {
    var body: some Widget {
        NextSetWidget()
        TestAlarmActivity()
    }
}

struct NextSetEntry: TimelineEntry {
    var date: Date
    var title: String
    var reps: String
    var detail: String
    var day: String
    var refreshAt: Date? = nil
}

struct NextSetProvider: TimelineProvider {
    func placeholder(in context: Context) -> NextSetEntry {
        NextSetEntry(date: Date(), title: "Next set 10:45 a.m.", reps: "30", detail: "Day 3", day: "Day 3 of 14")
    }

    func getSnapshot(in context: Context, completion: @escaping (NextSetEntry) -> Void) {
        completion(entry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NextSetEntry>) -> Void) {
        let current = entry()
        // Refresh at the next set's time, or in 15 minutes, whichever comes first.
        let soon = Date().addingTimeInterval(15 * 60)
        let refresh = min(current.refreshAt ?? soon, soon)
        completion(Timeline(entries: [current], policy: .after(refresh)))
    }

    private func entry() -> NextSetEntry {
        FontRegistration.register(bundle: .main)
        let now = Date()
        let state = WidgetState.make(run: LibraryDisk.load().current, now: CivilDateTime.local(now))
        let lines = Copy.widgetLines(state)
        var refreshAt: Date?
        var day = ""
        if case .next(let number, let at, _) = state {
            // Only a future set time; an overdue set waits for the regular refresh.
            refreshAt = at.foundationDate().flatMap { $0 > now ? $0.addingTimeInterval(60) : nil }
            day = Copy.dayProgress(number)
        }
        return NextSetEntry(date: now, title: lines.title, reps: lines.big, detail: lines.detail, day: day, refreshAt: refreshAt)
    }
}

struct NextSetWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "NextSet", provider: NextSetProvider()) { entry in
            NextSetView(entry: entry)
        }
        .configurationDisplayName(Copy.wordmark)
        .description("The next set, and when.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
    }
}

struct NextSetView: View {
    @Environment(\.widgetFamily) private var family
    var entry: NextSetEntry

    var body: some View {
        content
            .containerBackground(for: .widget) {
                if family == .accessoryRectangular {
                    AccessoryWidgetBackground()
                } else {
                    Chalk.ground
                }
            }
    }

    @ViewBuilder
    private var content: some View {
        switch family {
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.title)
                    .font(.footnote.weight(.semibold))
                Text(entry.detail)
                    .font(Chalk.display(28, weight: .extraBold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        default:
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.day.isEmpty ? entry.title : entry.day)
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(Chalk.inkMuted)
                Text(entry.reps)
                    .font(Chalk.display(family == .systemMedium ? 72 : 56, weight: .extraBold))
                    .foregroundStyle(Chalk.amber)
                    .lineLimit(1)
                    .minimumScaleFactor(0.4)
                Text(entry.day.isEmpty ? entry.detail : entry.title)
                    .font(.footnote)
                    .foregroundStyle(Chalk.ink)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
    }
}

struct TestAlarmActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AlarmAttributes<RepBellAlarmMetadata>.self) { _ in
            Text(Copy.testAlarm)
                .font(Chalk.display(24))
                .textCase(.uppercase)
                .foregroundStyle(Chalk.ink)
                .padding()
                .activityBackgroundTint(Chalk.ground)
        } dynamicIsland: { _ in
            DynamicIsland {
                DynamicIslandExpandedRegion(.center) {
                    Text(Copy.testAlarm)
                }
            } compactLeading: {
                Text("14")
            } compactTrailing: {
                Text("Test")
            } minimal: {
                Text("14")
            }
        }
    }
}
