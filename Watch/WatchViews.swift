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
                        .font(.custom("BarlowCondensed-ExtraBold", size: 48))
                        .foregroundStyle(Color(red: 1, green: 0x6A / 255, blue: 0x13 / 255))
                    Text("Open Rep Bell on iPhone.")
                        .font(.system(size: 13))
                        .foregroundStyle(Color(red: 0xC9 / 255, green: 0xC6 / 255, blue: 0xC0 / 255))
                        .multilineTextAlignment(.center)
                }
                .padding(8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}

private struct WatchAlert: View {
    @Environment(WatchModel.self) private var model
    var day: Int
    var total: Int
    var set: ScheduledSet

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Set \(set.index) of \(total)")
                .font(.system(size: 13))
                .foregroundStyle(Color(red: 0xA3 / 255, green: 0xA0 / 255, blue: 0x9A / 255))
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\(set.reps)")
                    .font(.custom("BarlowCondensed-ExtraBold", size: 72))
                    .foregroundStyle(Color(red: 1, green: 0x6A / 255, blue: 0x13 / 255))
                Text("now")
                    .font(.custom("BarlowCondensed-Bold", size: 24))
                    .textCase(.uppercase)
            }
            Spacer(minLength: 4)
            Button(Copy.done) { model.done(day: day, index: set.index) }
                .font(.system(size: 16, weight: .semibold))
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Color(red: 1, green: 0x6A / 255, blue: 0x13 / 255))
                .foregroundStyle(Color(red: 0x12 / 255, green: 0x12 / 255, blue: 0x12 / 255))
                .clipShape(Capsule())
                .buttonStyle(.plain)
            Button(Copy.inTen) { model.snooze(day: day, index: set.index) }
                .font(.system(size: 16, weight: .medium))
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Color(red: 0x26 / 255, green: 0x26 / 255, blue: 0x24 / 255))
                .foregroundStyle(Color(red: 0xF2 / 255, green: 0xF0 / 255, blue: 0xEB / 255))
                .clipShape(Capsule())
                .buttonStyle(.plain)
        }
        .padding(.horizontal, 6)
        .padding(.top, 8)
    }
}

private struct WatchToday: View {
    var resolved: ResolvedRun
    var now: CivilDateTime

    var body: some View {
        let number = resolved.input.dayNumber(on: now.date) ?? 1
        let day = resolved.day(number)
        let next = day?.sets.first { $0.status == .upcoming }
        VStack(alignment: .leading, spacing: 2) {
            Text(Copy.dayProgress(min(number, 14)))
                .font(.custom("BarlowCondensed-Bold", size: 17))
                .textCase(.uppercase)
                .foregroundStyle(Color(red: 1, green: 0x6A / 255, blue: 0x13 / 255))
            if let next, let alert = next.alert {
                Text("Next at \(Copy.clock(alert))")
                    .font(.system(size: 13))
                    .foregroundStyle(Color(red: 0xA3 / 255, green: 0xA0 / 255, blue: 0x9A / 255))
                Text("\(next.reps)")
                    .font(.custom("BarlowCondensed-ExtraBold", size: 64))
                    .foregroundStyle(Color(red: 0xF2 / 255, green: 0xF0 / 255, blue: 0xEB / 255))
            }
            Spacer(minLength: 4)
            if let day {
                let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
                LazyVGrid(columns: columns, spacing: 4) {
                    ForEach(day.sets, id: \.id) { set in
                        Capsule()
                            .fill(fill(set, current: next?.index))
                            .frame(height: 8)
                            .overlay {
                                if set.status == .missed {
                                    Capsule().stroke(Color(red: 0x6E / 255, green: 0x6B / 255, blue: 0x66 / 255), style: StrokeStyle(lineWidth: 1, dash: [2, 1]))
                                }
                            }
                    }
                }
                Text(Copy.watchTally(done: day.doneCount, total: day.sets.count, reps: day.loggedReps))
                    .font(.system(size: 13))
                    .foregroundStyle(Color(red: 0xA3 / 255, green: 0xA0 / 255, blue: 0x9A / 255))
            }
        }
        .padding(.horizontal, 4)
        .padding(.top, 6)
    }

    private func fill(_ set: ScheduledSet, current: Int?) -> Color {
        if set.status == .missed { return .clear }
        if set.index == current { return Color(red: 1, green: 0x6A / 255, blue: 0x13 / 255) }
        if set.status == .done { return Color(red: 0xF2 / 255, green: 0xF0 / 255, blue: 0xEB / 255) }
        return Color(red: 0x2E / 255, green: 0x2D / 255, blue: 0x2A / 255)
    }
}
