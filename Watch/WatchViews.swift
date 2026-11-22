import RepBellEngine
import SwiftUI

struct WatchRoot: View {
    @Environment(WatchModel.self) private var model

    var body: some View {
        Group {
            if let resolved = model.resolvedNow(), let run = model.library.current {
                let now = run.pausedAt ?? CivilDateTime.local(Date())
                if let number = run.input.dayNumber(on: now.date), let day = resolved.day(number),
                   let current = day.sets.first(where: { $0.status == .upcoming }),
                   let alert = current.alert, alert <= now {
                    WatchAlert(day: number, total: day.sets.count, set: current)
                } else {
                    WatchToday(resolved: resolved, now: now)
                }
            } else {
                VStack(spacing: 6) {
                    Text("14")
                        .font(Chalk.display(48, weight: .extraBold))
                        .foregroundStyle(Chalk.volt)
                    Text("Open Rep Bell on iPhone.")
                        .font(.footnote)
                        .foregroundStyle(Chalk.inkMuted)
                        .multilineTextAlignment(.center)
                }
                .padding(8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Chalk.groundWatch)
    }
}

private struct WatchAlert: View {
    @Environment(WatchModel.self) private var model
    var day: Int
    var total: Int
    var set: ScheduledSet

    var body: some View {
        // The bell-ring flood: the whole set screen turns dark olive, the number in volt (22 Nov 2026).
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: "bell.fill")
                    .font(.footnote)
                    .foregroundStyle(Chalk.volt)
                    .accessibilityHidden(true)
                Text("Set \(set.index) of \(total)")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Chalk.floodSoft)
            }
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\(set.reps)")
                    .font(Chalk.display(72, weight: .extraBold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .foregroundStyle(Chalk.volt)
                Text("now")
                    .font(Chalk.display(24, weight: .bold))
                    .textCase(.uppercase)
                    .foregroundStyle(Chalk.floodSoft)
            }
            Spacer(minLength: 4)
            Button(Copy.done) { model.done(day: day, index: set.index) }
                .font(.body.weight(.semibold))
                .frame(maxWidth: .infinity)
                .frame(minHeight: 44)
                .background(Chalk.volt)
                .foregroundStyle(Chalk.onVolt)
                .clipShape(Capsule())
                .buttonStyle(.plain)
            Button(Copy.inTen) { model.snooze(day: day, index: set.index) }
                .font(.body.weight(.medium))
                .frame(maxWidth: .infinity)
                .frame(minHeight: 44)
                .foregroundStyle(Chalk.ink)
                .overlay(Capsule().stroke(Chalk.floodSoft, lineWidth: 1.5))
                .buttonStyle(.plain)
        }
        .padding(.horizontal, 6)
        .padding(.top, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Chalk.flood.ignoresSafeArea())
        // Done and In 10 stay on screen at every text size.
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }
}

private struct WatchToday: View {
    @Environment(WatchModel.self) private var model
    var resolved: ResolvedRun
    var now: CivilDateTime

    var body: some View {
        let number = resolved.input.dayNumber(on: now.date) ?? 1
        let day = resolved.day(number)
        let next = day?.sets.first { $0.status == .upcoming }
        ScrollView {
        VStack(alignment: .leading, spacing: 2) {
            Text(Copy.dayProgress(min(number, 14)))
                .font(Chalk.display(17, weight: .bold))
                .textCase(.uppercase)
                .foregroundStyle(Chalk.volt)
            if let next, let alert = next.alert {
                Text("Next at \(Copy.clock(alert))")
                    .font(.footnote)
                    .foregroundStyle(Chalk.inkMuted)
                Text("\(next.reps)")
                    .font(Chalk.display(64, weight: .extraBold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .foregroundStyle(Chalk.volt)
            }
            Spacer(minLength: 4)
            if let day {
                let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
                LazyVGrid(columns: columns, spacing: 4) {
                    ForEach(day.sets, id: \.id) { set in
                        Capsule()
                            .fill(fill(set, current: next?.index))
                            // The current set is taller, so it never relies on color alone.
                            .frame(height: set.index == next?.index ? 12 : 8)
                            .overlay {
                                if set.status == .missed {
                                    Capsule().stroke(Chalk.inkFaint, style: StrokeStyle(lineWidth: 1, dash: [2, 1]))
                                }
                            }
                    }
                }
                Text(Copy.watchTally(done: day.doneCount, total: day.sets.count, reps: day.loggedReps))
                    .font(.footnote)
                    .foregroundStyle(Chalk.inkMuted)
            }
            if let busy = model.activeBusy() {
                Text(Copy.busyStrip(until: busy.until, skipped: busy.skipped))
                    .font(.footnote)
                    .foregroundStyle(Chalk.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)
            } else if next != nil, resolved.input.dayNumber(on: now.date) != nil {
                Button(Copy.busy) { model.busy() }
                    .font(.footnote.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 44)
                    .background(Chalk.watchSecondary)
                    .foregroundStyle(Chalk.ink)
                    .clipShape(Capsule())
                    .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 4)
        .padding(.top, 6)
        }
    }

    private func fill(_ set: ScheduledSet, current: Int?) -> Color {
        if set.status == .missed { return .clear }
        if set.index == current { return Chalk.volt }
        if set.status == .done { return Chalk.ink }
        return Chalk.line
    }
}
