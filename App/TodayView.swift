import RepBellEngine
import SwiftUI

struct TodayView: View {
    @Environment(ProgramController.self) private var controller

    var body: some View {
        let model = controller.todaySnapshot()
        ScreenChrome {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(model.eyebrow)
                            .font(Chalk.display(22, weight: .bold))
                            .tracking(0.8)
                            .textCase(.uppercase)
                        Spacer()
                        if let maxText = model.maxText {
                            Text(maxText)
                                .font(.system(size: 14))
                                .foregroundStyle(Chalk.inkMuted)
                        }
                        Button { controller.screen = .profile } label: {
                            Image(systemName: "person.crop.circle")
                                .font(.system(size: 24, weight: .regular))
                                .foregroundStyle(Chalk.inkSoft)
                                .frame(width: 44, height: 44)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(Copy.profileLabel)
                    }
                    if !model.bars.isEmpty {
                        DayBars(marks: model.bars)
                            .accessibilityLabel(model.eyebrow)
                    }
                }
                hero(model)
                if let fallback = model.fallback {
                    Text(fallback)
                        .font(.system(size: 15))
                        .foregroundStyle(Chalk.inkSoft)
                }
                if let title = model.tallyTitle, let detail = model.tallyDetail {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(title)
                                .font(.system(size: 15, weight: .semibold))
                            Spacer()
                            Text(detail)
                                .font(.system(size: 14))
                                .foregroundStyle(Chalk.inkMuted)
                        }
                        SetTally(marks: model.marks)
                        if let soFar = model.soFar {
                            Text(soFar)
                                .font(.system(size: 14))
                                .foregroundStyle(Chalk.inkMuted)
                        }
                    }
                }
                Spacer(minLength: 12)
                footer(model)
            }
        }
        .sheet(isPresented: Bindable(controller).showBusyConfirm) {
            BusySheet()
                .environment(controller)
        }
    }

    @ViewBuilder
    private func hero(_ model: TodaySnapshot) -> some View {
        switch model.hero {
        case .waiting(let eyebrow, let time, let title, let detail):
            VStack(alignment: .leading, spacing: 8) {
                Text(eyebrow)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Chalk.inkMuted)
                Text(time)
                    .font(Chalk.display(150))
                    .foregroundStyle(Chalk.accent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.3)
                Text(title)
                    .font(Chalk.display(44))
                    .textCase(.uppercase)
                Text(detail)
                    .font(.system(size: 16))
                    .foregroundStyle(Chalk.inkSoft)
            }
        case .test:
            VStack(alignment: .leading, spacing: 8) {
                Text(Copy.testAlarm)
                    .font(Chalk.display(44))
                    .textCase(.uppercase)
                    .foregroundStyle(Chalk.ink)
                Text(Copy.counterPrompt)
                    .font(.system(size: 16))
                    .foregroundStyle(Chalk.inkSoft)
            }
        case .next(let time, let reps, let line):
            VStack(alignment: .leading, spacing: 4) {
                Text(time)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Chalk.inkMuted)
                Text("\(reps)")
                    .font(Chalk.display(160))
                    .foregroundStyle(Chalk.accent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.25)
                Text(line)
                    .font(Chalk.display(28, weight: .bold))
                    .tracking(0.6)
                    .textCase(.uppercase)
            }
        case .finished(let line):
            Text(line)
                .font(Chalk.display(40))
                .textCase(.uppercase)
                .foregroundStyle(Chalk.ink)
        case .paused(let day):
            VStack(alignment: .leading, spacing: 8) {
                Text(Copy.paused)
                    .font(Chalk.display(48))
                    .textCase(.uppercase)
                    .foregroundStyle(Chalk.accent)
                Text(Copy.pauseDetail(day: day))
                    .font(.system(size: 16))
                    .foregroundStyle(Chalk.inkSoft)
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
                    PrimaryButton(title: Copy.doneSet(due.reps)) { controller.logDone(day: due.day, index: due.index) }
                }
                if let end = controller.activeBusyEnd() {
                    HStack {
                        Text(Copy.busyActive(Copy.clock(end)))
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Chalk.inkSoft)
                        Spacer()
                        TextLink(title: Copy.undo) { controller.undoBusy() }
                    }
                    .padding(.leading, 16)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Chalk.line, lineWidth: 1.5))
                } else if model.showBusy {
                    SecondaryButton(title: Copy.busy, height: 56) { controller.showBusyConfirm = true }
                    Text(Copy.busyCaption)
                        .font(.system(size: 13))
                        .foregroundStyle(Chalk.inkMuted)
                        .multilineTextAlignment(.center)
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
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 11)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 6) {
            ForEach(Array(marks.enumerated()), id: \.offset) { _, mark in
                markView(mark)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Copy.todaysSets)
    }

    @ViewBuilder
    private func markView(_ mark: SetMark) -> some View {
        switch mark {
        case .done:
            RoundedRectangle(cornerRadius: 6).fill(Chalk.ink).frame(height: 22)
        case .current:
            RoundedRectangle(cornerRadius: 6).fill(Chalk.accent).frame(height: 22)
        case .upcoming:
            RoundedRectangle(cornerRadius: 6)
                .stroke(Chalk.lineStrong, lineWidth: 1.5)
                .frame(height: 22)
        case .missed:
            RoundedRectangle(cornerRadius: 6)
                .stroke(Chalk.inkFaint, style: StrokeStyle(lineWidth: 1.5, dash: [3, 2]))
                .frame(height: 22)
        }
    }
}
