import Foundation

/// The animated line figures for Workouts movements and desk stretches (App/Studio/figures.json, built by
/// tools/build_figures.py). Each clip is a few key positions; the app eases between them in a loop.
/// Positions are numbers, not art or outside media, so they ship with the app and need no network.
public struct FigureLibrary: Decodable, Sendable {
    public let version: Int
    public let box: [Double]
    public let floor: Double
    public let clips: [String: FigureClip]

    public static func decode(_ data: Data) throws -> FigureLibrary {
        try JSONDecoder().decode(FigureLibrary.self, from: data)
    }
}

public struct FigurePoint: Sendable, Equatable {
    public var x: Double
    public var y: Double

    public init(_ x: Double, _ y: Double) {
        self.x = x
        self.y = y
    }
}

public struct FigureProp: Decodable, Sendable, Equatable {
    /// line, rect, chair, board, bell, bag or band.
    public let kind: String
    public let pts: [[Double]]?
    public let width: Double?
    public let r: Double?
    /// For bell, bag and band: the joint the prop moves with.
    public let follow: String?
}

public struct FigureArrow: Decodable, Sendable, Equatable {
    public let at: [Double]
    public let r: Double
    public let from: Double
    public let to: Double
}

public struct FigureClip: Decodable, Sendable, Equatable {
    /// side, front or hand.
    public let view: String
    public let frames: [[String: [Double]]]
    /// Seconds to move from one key position to the next.
    public let seconds: Double
    /// Seconds to hold each key position.
    public let hold: Double
    public let floor: Bool
    /// The key position shown with Reduce Motion on.
    public let still: Int
    public let props: [FigureProp]?
    public let arrows: [FigureArrow]?
    /// For hand close-ups: twist, grab, spread or squeeze.
    public let hand: String?
    public let bucket: Bool?

    /// One full loop through every key position and back to the first.
    public var cycle: Double { Double(max(frames.count, 1)) * (seconds + hold) }

    /// Where the loop is at time t: easing from one key position to the next.
    public func phase(at t: Double) -> (from: Int, to: Int, progress: Double) {
        let n = max(frames.count, 1)
        guard n > 1, cycle > 0 else { return (0, 0, 0) }
        let step = seconds + hold
        var local = t.truncatingRemainder(dividingBy: cycle)
        if local < 0 { local += cycle }
        let index = min(n - 1, Int(local / step))
        let within = local - Double(index) * step
        let next = (index + 1) % n
        guard within > hold, seconds > 0 else { return (index, next, 0) }
        return (index, next, Self.ease(min(1, (within - hold) / seconds)))
    }

    /// The figure's joints at time t.
    public func pose(at t: Double) -> [String: FigurePoint] {
        let p = phase(at: t)
        return blend(p.from, p.to, p.progress)
    }

    /// The still position for Reduce Motion.
    public var stillPose: [String: FigurePoint] {
        let i = min(max(0, still), max(0, frames.count - 1))
        return blend(i, i, 0)
    }

    /// For hand close-ups: 0 at the first position, 1 at the second.
    public func handProgress(at t: Double) -> Double {
        let p = phase(at: t)
        return p.from == 0 ? p.progress : 1 - p.progress
    }

    private func blend(_ a: Int, _ b: Int, _ u: Double) -> [String: FigurePoint] {
        guard frames.indices.contains(a), frames.indices.contains(b) else { return [:] }
        var out: [String: FigurePoint] = [:]
        for (joint, p) in frames[a] where p.count == 2 {
            let q = frames[b][joint] ?? p
            out[joint] = FigurePoint(p[0] + (q[0] - p[0]) * u, p[1] + (q[1] - p[1]) * u)
        }
        return out
    }

    /// Smooth start and finish.
    static func ease(_ x: Double) -> Double {
        x < 0.5 ? 4 * x * x * x : 1 - pow(-2 * x + 2, 3) / 2
    }

    /// Joints every body clip carries; front views also carry the second shoulder and hip.
    public static let bodyJoints = ["hd", "nk", "sh", "hp", "el", "ha", "el2", "ha2", "kn", "ft", "kn2", "ft2"]
}
