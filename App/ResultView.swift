import RepBellEngine
import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct ResultView: View {
    @Environment(ProgramController.self) private var controller

    var body: some View {
        let numbers = controller.resultNumbers()
        ScreenChrome(top: 16) {
            VStack(alignment: .leading, spacing: 20) {
                Text(numbers.end == nil ? Copy.runEnded(day: controller.endedDay() ?? 1) : "Day 15 · Final test")
                    .eyebrow()
                ResultCard(start: numbers.start, end: numbers.end, reps: numbers.reps, percent: numbers.percent)
                if numbers.end == nil {
                    Text(Copy.endDetail)
                        .font(.body)
                        .foregroundStyle(Chalk.inkSoft)
                }
                if numbers.end != nil, controller.library.current?.ended == false {
                    TextLink(title: Copy.fixMyNumber) { controller.fixFinalNumber() }
                }
                Spacer(minLength: 12)
                if let image = render(start: numbers.start, end: numbers.end, reps: numbers.reps, percent: numbers.percent) {
                    ShareLink(item: ShareImage(image: image), preview: SharePreview(Copy.wordmark, image: Image(uiImage: image))) {
                        Text(Copy.share)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
                HStack(spacing: 12) {
                    SecondaryButton(title: Copy.runAgain, height: 56) { controller.runAgain() }
                    SecondaryButton(title: Copy.done, height: 56) { controller.screen = .today }
                }
            }
        }
    }

    @MainActor
    private func render(start: Int, end: Int?, reps: Int, percent: Int?) -> UIImage? {
        let renderer = ImageRenderer(content: ResultCard(start: start, end: end, reps: reps, percent: percent).padding(24).background(Chalk.ground).frame(width: 390))
        renderer.scale = 3
        return renderer.uiImage
    }
}

struct ResultCard: View {
    var start: Int
    var end: Int?
    var reps: Int
    var percent: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .bottom, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Day 1")
                        .font(.subheadline)
                        .foregroundStyle(Chalk.inkMuted)
                    Text("\(start)")
                        .font(Chalk.display(72))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .foregroundStyle(Chalk.inkFaint)
                }
                Image(systemName: "arrow.right")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Chalk.ink)
                    .padding(.bottom, 12)
                VStack(alignment: .leading, spacing: 4) {
                    Text(end == nil ? "Saved" : "Day 15")
                        .font(.subheadline)
                        .foregroundStyle(Chalk.inkMuted)
                    Text(end.map(String.init) ?? "—")
                        .font(Chalk.display(96))
                        .foregroundStyle(Chalk.accent)
                        .lineLimit(1)
                        .minimumScaleFactor(0.4)
                }
            }
            Rectangle().fill(Chalk.line).frame(height: 1.5)
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(Copy.grouped(reps))
                        .font(Chalk.display(32, weight: .bold))
                    Text(end == nil ? "push-ups so far" : "push-ups in 14 days")
                        .font(.subheadline)
                        .foregroundStyle(Chalk.inkMuted)
                }
                Spacer()
                if let percent {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(Copy.signedPercent(percent))
                            .font(Chalk.display(32, weight: .bold))
                        Text("on your max")
                            .font(.subheadline)
                            .foregroundStyle(Chalk.inkMuted)
                    }
                }
            }
        }
        .padding(24)
        .background(Chalk.surface)
        .overlay(RoundedRectangle(cornerRadius: ChalkTokens.Radius.panel).stroke(Chalk.line, lineWidth: 1.5))
        .clipShape(RoundedRectangle(cornerRadius: ChalkTokens.Radius.panel))
    }
}

struct ShareImage: Transferable {
    var image: UIImage
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .png) { item in
            item.image.pngData() ?? Data()
        }
    }
}
