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
        let refresh = current.date.addingTimeInterval(15 * 60)
        completion(Timeline(entries: [current], policy: .after(refresh)))
    }

    private func entry() -> NextSetEntry {
        FontRegistration.register(bundle: .main)
        let now = Date()
        guard let library = LibraryDisk.load().current else {
            return NextSetEntry(date: now, title: Copy.wordmark, reps: "14", detail: "Your max goes up.", day: "")
        }
        let moment = CivilDateTime.local(now)
        let resolved = ScheduleEngine.resolve(library.input, now: library.pausedAt ?? moment)
        guard let number = library.input.dayNumber(on: moment.date), let day = resolved.day(number) else {
            return NextSetEntry(date: now, title: "Day 1", reps: Copy.hourMinute(library.input.wake), detail: Copy.withYourTest, day: "")
        }
        if let next = day.sets.first(where: { $0.status == .upcoming }), let alert = next.alert {
            return NextSetEntry(
                date: alert.foundationDate() ?? now,
                title: Copy.widgetNext(alert),
                reps: "\(next.reps)",
                detail: Copy.widgetReps(reps: next.reps, day: number),
                day: Copy.dayProgress(number)
            )
        }
        return NextSetEntry(date: now, title: Copy.dayProgress(number), reps: "\(day.doneCount)", detail: "of \(day.sets.count)", day: Copy.dayProgress(number))
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
                    .foregroundStyle(Chalk.accent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.4)
                Text(entry.title)
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
