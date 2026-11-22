import RepBellEngine
import SwiftUI
import UIKit

struct PromiseView: View {
    @Environment(ProgramController.self) private var controller

    var body: some View {
        ScreenChrome(top: 24) {
            VStack(alignment: .leading, spacing: 24) {
                Wordmark()
                    .padding(.bottom, 8)
                Text(Copy.promiseHeadlineLead)
                    .font(Chalk.display(160))
                    .foregroundStyle(Chalk.volt)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                Text(Copy.promiseHeadline)
                    .font(Chalk.display(56))
                    .textCase(.uppercase)
                    .foregroundStyle(Chalk.ink)
                    .lineSpacing(-2)
                Text(Copy.promiseBody)
                    .font(.body)
                    .foregroundStyle(Chalk.inkMuted)
                    .lineSpacing(4)
                Spacer(minLength: 16)
                PrimaryButton(title: Copy.start) { controller.screen = .wake }
                Text(Copy.healthNote)
                    .font(.footnote)
                    .foregroundStyle(Chalk.inkMuted)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

struct WakeView: View {
    @Environment(ProgramController.self) private var controller

    var body: some View {
        ScreenChrome {
            VStack(alignment: .leading, spacing: 24) {
                StepBars(filled: 1)
                Text(Copy.wakeHeadline)
                    .font(Chalk.display(48))
                    .textCase(.uppercase)
                    .foregroundStyle(Chalk.ink)
                    .padding(.top, 8)
                Text(Copy.wakeBody)
                    .font(.body)
                    .foregroundStyle(Chalk.inkMuted)
                    .lineSpacing(4)
                TimeWheel(choices: controller.wakeChoices(), selection: Bindable(controller).draftWake)
                    .padding(.top, 16)
                Spacer(minLength: 16)
                PrimaryButton(title: Copy.next) { controller.screen = .bed }
            }
        }
    }
}

struct BedView: View {
    @Environment(ProgramController.self) private var controller

    var body: some View {
        ScreenChrome {
            VStack(alignment: .leading, spacing: 24) {
                StepBars(filled: 2)
                Text(Copy.bedHeadline)
                    .font(Chalk.display(48))
                    .textCase(.uppercase)
                    .foregroundStyle(Chalk.ink)
                    .padding(.top, 8)
                Text(Copy.bedBody)
                    .font(.body)
                    .foregroundStyle(Chalk.inkMuted)
                TimeWheel(choices: controller.bedChoices(), selection: Bindable(controller).draftBed)
                    .padding(.top, 16)
                Text(controller.lastSetLabel())
                    .font(.subheadline)
                    .foregroundStyle(Chalk.inkMuted)
                    .frame(maxWidth: .infinity)
                Spacer(minLength: 16)
                PrimaryButton(title: Copy.next) { controller.screen = .startDay }
            }
        }
    }
}

struct StartDayView: View {
    @Environment(ProgramController.self) private var controller

    var body: some View {
        ScreenChrome {
            VStack(alignment: .leading, spacing: 24) {
                StepBars(filled: 3)
                Text(Copy.startHeadline)
                    .font(Chalk.display(48))
                    .textCase(.uppercase)
                    .foregroundStyle(Chalk.ink)
                    .padding(.top, 8)
                Text(Copy.startBody)
                    .font(.body)
                    .foregroundStyle(Chalk.inkMuted)
                Spacer(minLength: 16)
                ChoiceCard(title: Copy.tomorrowMorning, detail: controller.tomorrowDetail(), recommended: true) {
                    controller.draftStartsToday = false
                    controller.screen = .alerts
                }
                ChoiceCard(title: Copy.today, detail: controller.todayDetail(), recommended: false) {
                    controller.draftStartsToday = true
                    controller.screen = .alerts
                }
            }
        }
    }
}

struct AlertsView: View {
    @Environment(ProgramController.self) private var controller
    @Environment(\.openURL) private var openURL

    var body: some View {
        ScreenChrome {
            VStack(alignment: .leading, spacing: 24) {
                StepBars(filled: 4)
                Text(controller.alertsDenied ? Copy.alertsDeniedHeadline : Copy.alertsHeadline)
                    .font(Chalk.display(48))
                    .textCase(.uppercase)
                    .foregroundStyle(Chalk.ink)
                    .padding(.top, 8)
                Text(controller.alertsDenied ? Copy.alertsDeniedBody : Copy.alertsBody)
                    .font(.body)
                    .foregroundStyle(Chalk.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)
                VStack(spacing: 12) {
                    AlertRow(symbol: "bell", title: Copy.setAlertsTitle, detail: Copy.setAlertsDetail)
                    AlertRow(symbol: "alarm", title: Copy.testAlarmTitle, detail: Copy.testAlarmDetail)
                }
                Spacer(minLength: 16)
                if controller.alertsDenied {
                    PrimaryButton(title: Copy.openSettings) {
                        if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                            openURL(url)
                        }
                    }
                    TextLink(title: Copy.startWithoutAlerts) {
                        Task { await controller.startWithoutAlerts() }
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityHint(Copy.startWithoutAlertsDetail)
                } else {
                    PrimaryButton(title: Copy.allowAlerts) {
                        Task { await controller.allowAlerts() }
                    }
                }
            }
        }
    }
}

struct ReadyView: View {
    @Environment(ProgramController.self) private var controller

    var body: some View {
        ScreenChrome {
            VStack(alignment: .leading, spacing: 24) {
                StepBars(filled: 5)
                Spacer(minLength: 12)
                Text(Copy.setupReady(when: controller.draftStartsToday ? "today" : "tomorrow"))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Chalk.inkMuted)
                Text(Copy.hourMinute(controller.library.current?.input.wake ?? controller.draftWake))
                    .font(Chalk.display(150))
                    .foregroundStyle(Chalk.volt)
                    .lineLimit(1)
                    .minimumScaleFactor(0.4)
                Text(Copy.withYourTest)
                    .font(Chalk.display(44))
                    .textCase(.uppercase)
                    .foregroundStyle(Chalk.ink)
                Text(Copy.nothingElse)
                    .font(.body)
                    .foregroundStyle(Chalk.inkMuted)
                Spacer(minLength: 12)
                SecondaryButton(title: Copy.done) { controller.finishReady() }
            }
        }
    }
}

private struct TimeWheel: View {
    var choices: [ClockTime]
    @Binding var selection: ClockTime
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        // A wheel's rows have a fixed height, so large text can't fit; at accessibility sizes it's a menu.
        if typeSize.isAccessibilitySize {
            Picker("Time", selection: $selection) {
                ForEach(choices, id: \.self) { time in
                    Text(Copy.clock(time)).tag(time)
                }
            }
            .pickerStyle(.menu)
            .tint(Chalk.volt)
            .labelsHidden()
            .frame(minHeight: ChalkTokens.minimumTarget)
            .accessibilityLabel("Time")
        } else {
            wheel
        }
    }

    private var wheel: some View {
        Picker("Time", selection: $selection) {
            ForEach(choices, id: \.self) { time in
                Text(Copy.clock(time))
                    .font(Chalk.display(34, weight: .bold))
                    .tag(time)
            }
        }
        .pickerStyle(.wheel)
        .labelsHidden()
        .frame(height: 220)
        .accessibilityLabel("Time")
    }
}

private struct AlertRow: View {
    var symbol: String
    var title: String
    var detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(Chalk.volt)
                .frame(width: 28, height: 28)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Chalk.ink)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(Chalk.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Chalk.line, lineWidth: 1.5))
    }
}

/// The start of each program day: the day, its sets, and Ring or Quiet, with yesterday's choice first.
struct DayStartView: View {
    @Environment(ProgramController.self) private var controller

    var body: some View {
        let model = controller.dayStartModel()
        ScreenChrome(top: 24) {
            VStack(alignment: .leading, spacing: 20) {
                Text(Copy.dayProgress(model.day))
                    .eyebrow(Chalk.inkMuted)
                Text(Copy.dayStart(day: model.day, sets: model.sets))
                    .font(Chalk.display(56))
                    .textCase(.uppercase)
                    .foregroundStyle(Chalk.ink)
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: 16)
                let ringFirst = model.preselected == .ring
                ChoiceCard(title: ringFirst ? Copy.ringTitle : Copy.quietTitle,
                           detail: ringFirst ? Copy.ringDetail : Copy.quietDetail,
                           recommended: true) {
                    controller.chooseDay(ringFirst ? .ring : .quiet)
                }
                ChoiceCard(title: ringFirst ? Copy.quietTitle : Copy.ringTitle,
                           detail: ringFirst ? Copy.quietDetail : Copy.ringDetail,
                           recommended: false) {
                    controller.chooseDay(ringFirst ? .quiet : .ring)
                }
            }
        }
    }
}
