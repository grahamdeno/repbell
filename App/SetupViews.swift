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
                    .foregroundStyle(Chalk.accent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                Text(Copy.promiseHeadline)
                    .font(Chalk.display(56))
                    .textCase(.uppercase)
                    .foregroundStyle(Chalk.ink)
                    .lineSpacing(-2)
                Text(Copy.promiseBody)
                    .font(.system(size: 17))
                    .foregroundStyle(Chalk.inkSoft)
                    .lineSpacing(4)
                Spacer(minLength: 16)
                PrimaryButton(title: Copy.start) { controller.screen = .wake }
                Text(Copy.healthNote)
                    .font(.system(size: 13))
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
                    .font(.system(size: 16))
                    .foregroundStyle(Chalk.inkSoft)
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
                    .font(.system(size: 16))
                    .foregroundStyle(Chalk.inkSoft)
                TimeWheel(choices: controller.bedChoices(), selection: Bindable(controller).draftBed)
                    .padding(.top, 16)
                Text(controller.lastSetLabel())
                    .font(.system(size: 15))
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
                    .font(.system(size: 16))
                    .foregroundStyle(Chalk.inkSoft)
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
                Text(Copy.alertsHeadline)
                    .font(Chalk.display(48))
                    .textCase(.uppercase)
                    .foregroundStyle(Chalk.ink)
                    .padding(.top, 8)
                Text(Copy.alertsBody)
                    .font(.system(size: 16))
                    .foregroundStyle(Chalk.inkSoft)
                VStack(spacing: 12) {
                    AlertRow(symbol: "bell", title: Copy.setAlertsTitle, detail: Copy.setAlertsDetail)
                    AlertRow(symbol: "alarm", title: Copy.testAlarmTitle, detail: Copy.testAlarmDetail)
                }
                if controller.alertsDenied {
                    Text(Copy.alertsBody)
                        .font(.system(size: 15))
                        .foregroundStyle(Chalk.inkMuted)
                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            openURL(url)
                        }
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Chalk.accent)
                }
                Spacer(minLength: 16)
                PrimaryButton(title: Copy.allowAlerts) {
                    Task { await controller.allowAlerts() }
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
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Chalk.inkMuted)
                Text(Copy.hourMinute(controller.library.current?.input.wake ?? controller.draftWake))
                    .font(Chalk.display(150))
                    .foregroundStyle(Chalk.accent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.4)
                Text(Copy.withYourTest)
                    .font(Chalk.display(44))
                    .textCase(.uppercase)
                    .foregroundStyle(Chalk.ink)
                Text(Copy.nothingElse)
                    .font(.system(size: 16))
                    .foregroundStyle(Chalk.inkSoft)
                Spacer(minLength: 12)
                SecondaryButton(title: Copy.done) { controller.finishReady() }
            }
        }
    }
}

private struct TimeWheel: View {
    var choices: [ClockTime]
    @Binding var selection: ClockTime

    var body: some View {
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
                .font(.system(size: 22))
                .foregroundStyle(Chalk.accent)
                .frame(width: 28, height: 28)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Chalk.ink)
                Text(detail)
                    .font(.system(size: 15))
                    .foregroundStyle(Chalk.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Chalk.line, lineWidth: 1.5))
    }
}
