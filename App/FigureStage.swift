import RepBellEngine
import SwiftUI

/// Loads App/Studio/figures.json once.
enum Figures {
    static let library: FigureLibrary? = {
        guard let url = Bundle.main.url(forResource: "figures", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return nil }
        return try? FigureLibrary.decode(data)
    }()

    static func clip(_ id: String?) -> FigureClip? {
        guard let id else { return nil }
        return library?.clips[id]
    }
}

/// The animated line figure for one movement or stretch. With Reduce Motion on, or when `still` is set,
/// it shows the key position without moving. Decorative: the written cues carry the instructions.
struct FigureStage: View {
    var clip: FigureClip
    var tint: Color = Chalk.volt
    var still = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: still || reduceMotion)) { context in
            Canvas { gc, size in
                let t = context.date.timeIntervalSinceReferenceDate
                let frozen = still || reduceMotion
                if clip.view == "hand" {
                    FigureDrawing.hand(gc, size: size, clip: clip, u: frozen ? 1 : clip.handProgress(at: t), tint: tint)
                } else {
                    FigureDrawing.body(gc, size: size, clip: clip, pose: frozen ? clip.stillPose : clip.pose(at: t), tint: tint)
                }
            }
        }
        .accessibilityHidden(true)
    }
}

enum FigureDrawing {
    static let box = CGSize(width: 300, height: 200)

    /// Fits the 300 by 200 drawing box into the view, centered.
    static func fit(_ size: CGSize) -> (scale: CGFloat, dx: CGFloat, dy: CGFloat) {
        let s = min(size.width / box.width, size.height / box.height)
        return (s, (size.width - box.width * s) / 2, (size.height - box.height * s) / 2)
    }

    static func body(_ gc: GraphicsContext, size: CGSize, clip: FigureClip, pose: [String: FigurePoint], tint: Color) {
        let (s, dx, dy) = fit(size)
        func p(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: dx + x * s, y: dy + y * s) }
        func j(_ name: String) -> CGPoint? { pose[name].map { p($0.x, $0.y) } }
        let stroke = StrokeStyle(lineWidth: 6.5 * s, lineCap: .round, lineJoin: .round)

        if clip.floor {
            var floor = Path()
            floor.move(to: p(10, 184))
            floor.addLine(to: p(290, 184))
            gc.stroke(floor, with: .color(Chalk.line), style: StrokeStyle(lineWidth: 2 * s, lineCap: .round))
        }

        for prop in clip.props ?? [] {
            let pts = (prop.pts ?? []).map { p($0[0], $0[1]) }
            let propStroke = StrokeStyle(lineWidth: (prop.width ?? 3) * s, lineCap: .round, lineJoin: .round)
            switch prop.kind {
            case "line" where pts.count == 2:
                var path = Path(); path.move(to: pts[0]); path.addLine(to: pts[1])
                gc.stroke(path, with: .color(Chalk.lineStrong), style: propStroke)
            case "rect", "board", "chair":
                guard pts.count == 2 else { continue }
                let r = CGRect(x: min(pts[0].x, pts[1].x), y: min(pts[0].y, pts[1].y),
                               width: abs(pts[1].x - pts[0].x), height: abs(pts[1].y - pts[0].y))
                if prop.kind == "chair" {
                    var path = Path()
                    path.move(to: CGPoint(x: r.minX, y: r.minY)); path.addLine(to: CGPoint(x: r.maxX, y: r.minY))
                    path.move(to: CGPoint(x: r.minX + 3 * s, y: r.minY)); path.addLine(to: CGPoint(x: r.minX + 3 * s, y: r.maxY))
                    path.move(to: CGPoint(x: r.maxX - 3 * s, y: r.minY)); path.addLine(to: CGPoint(x: r.maxX - 3 * s, y: r.maxY))
                    gc.stroke(path, with: .color(Chalk.lineStrong), style: StrokeStyle(lineWidth: 3 * s, lineCap: .round))
                } else {
                    gc.stroke(Path(roundedRect: r, cornerRadius: (prop.kind == "board" ? 4 : 2) * s), with: .color(Chalk.lineStrong),
                              style: StrokeStyle(lineWidth: 2.5 * s))
                }
            case "bell", "bag":
                let r = (prop.r ?? 8) * s
                let c: CGPoint
                if let follow = prop.follow, let hand = j(follow) {
                    c = CGPoint(x: hand.x, y: hand.y + r + 1.5 * s)
                } else if let first = pts.first {
                    c = first
                } else { continue }
                gc.stroke(Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: 2 * r, height: 2 * r)),
                          with: .color(Chalk.inkMuted), style: StrokeStyle(lineWidth: 3 * s))
            case "band":
                guard let follow = prop.follow, let from = j(follow), let to = pts.first else { continue }
                var path = Path(); path.move(to: from); path.addLine(to: to)
                gc.stroke(path, with: .color(Chalk.inkMuted), style: StrokeStyle(lineWidth: 1.5 * s, lineCap: .round))
            default:
                continue
            }
        }

        for arrow in clip.arrows ?? [] where arrow.at.count == 2 {
            let c = p(arrow.at[0], arrow.at[1])
            let r = arrow.r * s
            var path = Path()
            path.addArc(center: c, radius: r, startAngle: .degrees(arrow.from), endAngle: .degrees(arrow.to), clockwise: false)
            gc.stroke(path, with: .color(Chalk.inkMuted), style: StrokeStyle(lineWidth: 2 * s, lineCap: .round))
            let end = Angle.degrees(arrow.to).radians
            let tip = CGPoint(x: c.x + r * cos(end), y: c.y + r * sin(end))
            let tangent = end + .pi / 2
            var head = Path()
            for side in [-0.5, 0.5] {
                let a = tangent + .pi + side
                head.move(to: tip)
                head.addLine(to: CGPoint(x: tip.x + 6 * s * cos(a), y: tip.y + 6 * s * sin(a)))
            }
            gc.stroke(head, with: .color(Chalk.inkMuted), style: StrokeStyle(lineWidth: 2 * s, lineCap: .round))
        }

        func segments(_ pairs: [(String, String)], _ color: Color) {
            var path = Path()
            for (a, b) in pairs {
                guard let pa = j(a), let pb = j(b) else { continue }
                path.move(to: pa); path.addLine(to: pb)
            }
            gc.stroke(path, with: .color(color), style: stroke)
        }

        if clip.view == "side" {
            // Far-side limbs first and dimmer, so depth reads.
            segments([("sh", "el2"), ("el2", "ha2"), ("hp", "kn2"), ("kn2", "ft2")], tint.opacity(0.45))
            segments([("nk", "hp"), ("sh", "el"), ("el", "ha"), ("hp", "kn"), ("kn", "ft")], tint)
        } else {
            if let h1 = pose["hp"], let h2 = pose["hp2"], let nk = j("nk") {
                var torso = Path()
                torso.move(to: nk)
                torso.addLine(to: p((h1.x + h2.x) / 2, (h1.y + h2.y) / 2))
                gc.stroke(torso, with: .color(tint), style: stroke)
            }
            // The screen-right arm is drawn first, so an arm that threads under reads as behind.
            segments([("sh2", "el2"), ("el2", "ha2")], tint.opacity(0.8))
            segments([("sh", "sh2"), ("hp", "hp2"), ("hp", "kn"), ("kn", "ft"), ("hp2", "kn2"), ("kn2", "ft2"), ("sh", "el"), ("el", "ha")], tint)
        }
        if let head = j("hd") {
            let r = 10 * s
            gc.fill(Path(ellipseIn: CGRect(x: head.x - r, y: head.y - r, width: 2 * r, height: 2 * r)), with: .color(tint))
        }
    }

    /// Hand close-ups for grip moves: a cut-away bucket of rice (or none) with the fist or fingers moving.
    static func hand(_ gc: GraphicsContext, size: CGSize, clip: FigureClip, u: Double, tint: Color) {
        let (s, dx, dy) = fit(size)
        func p(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: dx + x * s, y: dy + y * s) }
        let bucket = clip.bucket ?? true
        if bucket {
            var rice = Path()
            rice.move(to: p(88, 86)); rice.addLine(to: p(216, 86)); rice.addLine(to: p(204, 192)); rice.addLine(to: p(100, 192)); rice.closeSubpath()
            gc.fill(rice, with: .color(Color(red: 0.2, green: 0.2, blue: 0.19)))
            for i in 0..<70 {
                let fx = Double((i * 37) % 100) / 100, fy = Double((i * 61) % 100) / 100
                let y = 92 + fy * 94
                let inset = (y - 86) / 106 * 12
                let x = 92 + inset + fx * (120 - 2 * inset)
                gc.fill(Path(ellipseIn: CGRect(x: dx + x * s, y: dy + y * s, width: 4 * s, height: 2 * s)), with: .color(Chalk.lineStrong))
            }
            var tub = Path()
            tub.move(to: p(80, 50)); tub.addLine(to: p(100, 196)); tub.addLine(to: p(204, 196)); tub.addLine(to: p(224, 50))
            gc.stroke(tub, with: .color(Chalk.lineStrong), style: StrokeStyle(lineWidth: 3 * s, lineCap: .round, lineJoin: .round))
        }
        var arm = Path()
        arm.move(to: p(152, 8)); arm.addLine(to: p(152, 128))
        gc.stroke(arm, with: .color(tint), style: StrokeStyle(lineWidth: 16 * s, lineCap: .round))

        let motion = clip.hand ?? "grab"
        switch motion {
        case "twist":
            let a = (u * 2 - 1) * 1.2
            let w = 30 + 12 * abs(cos(a))
            gc.fill(Path(roundedRect: CGRect(x: dx + (152 - w / 2) * s, y: dy + 126 * s, width: w * s, height: 34 * s), cornerRadius: 12 * s), with: .color(tint))
            let kx = 152 + 15 * sin(a)
            gc.fill(Path(roundedRect: CGRect(x: dx + (kx - 4) * s, y: dy + 130 * s, width: 8 * s, height: 26 * s), cornerRadius: 4 * s),
                    with: .color(Chalk.ground.opacity(0.25 + 0.4 * abs(cos(a)))))
            var arc = Path()
            arc.addArc(center: p(152, 168), radius: 34 * s, startAngle: .degrees(20), endAngle: .degrees(160), clockwise: false)
            gc.stroke(arc, with: .color(Chalk.inkMuted), style: StrokeStyle(lineWidth: 2.5 * s, lineCap: .round))
            for (x, sign) in [(152 + 34 * cos(Double.pi / 9), 1.0), (152 - 34 * cos(Double.pi / 9), -1.0)] {
                var head = Path()
                let tip = p(x, 168 + 34 * sin(Double.pi / 9))
                head.move(to: tip); head.addLine(to: CGPoint(x: tip.x + sign * 2 * s, y: tip.y - 8 * s))
                head.move(to: tip); head.addLine(to: CGPoint(x: tip.x + sign * 8 * s, y: tip.y + 1 * s))
                gc.stroke(head, with: .color(Chalk.inkMuted), style: StrokeStyle(lineWidth: 2.5 * s, lineCap: .round))
            }
        case "spread":
            gc.fill(Path(roundedRect: CGRect(x: dx + 136 * s, y: dy + 122 * s, width: 32 * s, height: 26 * s), cornerRadius: 8 * s), with: .color(tint))
            var fingers = Path()
            for k in 0..<4 {
                let base = 140 + Double(k) * 8
                let angle = (Double(k) - 1.5) * 0.28 * u
                fingers.move(to: p(base, 146))
                fingers.addLine(to: p(base + 24 * sin(angle), 146 + 24 * cos(angle)))
            }
            fingers.move(to: p(138, 132)); fingers.addLine(to: p(138 - 14 - 6 * u, 140 + 6 * (1 - u)))
            gc.stroke(fingers, with: .color(tint), style: StrokeStyle(lineWidth: 6 * s, lineCap: .round))
        default:
            // grab and squeeze: an open hand closes into a fist.
            let len = 24 * (1 - u)
            let fistW = 32 + 6 * u, fistH = 24 + 10 * u
            gc.fill(Path(roundedRect: CGRect(x: dx + (152 - fistW / 2) * s, y: dy + 122 * s, width: fistW * s, height: fistH * s), cornerRadius: (8 + 4 * u) * s),
                    with: .color(tint))
            if len > 1 {
                var fingers = Path()
                for k in 0..<4 {
                    let x = 141 + Double(k) * 7.5
                    fingers.move(to: p(x, 144)); fingers.addLine(to: p(x, 144 + len))
                }
                fingers.move(to: p(137, 132)); fingers.addLine(to: p(137 - len * 0.6, 140 + len * 0.3))
                gc.stroke(fingers, with: .color(tint), style: StrokeStyle(lineWidth: 6 * s, lineCap: .round))
            }
        }
    }
}
