/// Fit my time (1.0, added 20 Nov 2026): pick how many minutes you have; Rep Bell builds one session that fits.
/// The focus follows the program day, so it never works against the push-ups.
public enum FitMyTime {
    public static let choices = [5, 10, 15, 20, 30, 45]
    public static let sessionID = "fit"

    public enum Focus: String, Sendable, Equatable {
        case legs, core, mobility, fullBody
    }

    public struct Move: Equatable, Sendable {
        public let id: String
        public let eachSide: Bool
        public init(id: String, eachSide: Bool) {
            self.id = id
            self.eachSide = eachSide
        }
    }

    public struct Pools: Sendable {
        public let warmUp: [Move]
        public let main: [Move]
        public let coolDown: [Move]
        public init(warmUp: [Move], main: [Move], coolDown: [Move]) {
            self.warmUp = warmUp
            self.main = main
            self.coolDown = coolDown
        }
    }

    /// One step in the same shape as the Workouts sessions file.
    public struct Step: Equatable, Sendable {
        public let type: String
        public let seconds: Int
        public let id: String?
        public let next: String?
        public let side: String?
    }

    /// Test mornings and the day after rest the body; other program days alternate legs and core;
    /// with no run going, anything goes.
    public static func focus(programDay: Int?) -> Focus {
        guard let day = programDay, day <= 15 else { return .fullBody }
        switch day {
        case 1, 2, 8, 9, 15: return .mobility
        default: return day % 2 == 0 ? .legs : .core
        }
    }

    /// Builds a session that lasts exactly `minutes`, with a warm-up, the main moves and a cool-down.
    /// `seed` changes the mix, for "Another one".
    public static func build(minutes: Int, pools: Pools, seed: Int) -> [Step] {
        let total = max(5, minutes) * 60
        var steps: [Step] = []
        var used = 0
        var random = SeededRandom(seed: seed)

        let warmUpBudget = minutes <= 5 ? 50 : min(240, total * 15 / 100)
        let coolDownBudget = minutes <= 5 ? 60 : min(240, total * 12 / 100)

        func add(_ step: Step) {
            steps.append(step)
            used += step.seconds
        }

        // Warm-up.
        let warmUp = pools.warmUp
        add(Step(type: "getReady", seconds: 10, id: nil, next: warmUp.first?.id, side: nil))
        var warmUsed = 0
        for (i, move) in warmUp.enumerated() {
            let length = move.eachSide ? 50 : 30
            guard warmUsed + length <= warmUpBudget else { break }
            if i > 0 { add(Step(type: "rest", seconds: 5, id: nil, next: move.id, side: nil)); warmUsed += 5 }
            warmUsed += place(move, seconds: length, into: &steps, used: &used)
        }

        // Main block: rounds through the shuffled pool until the time left is the cool-down.
        let main = random.shuffled(pools.main)
        let mainEnd = total - coolDownBudget
        if !main.isEmpty {
            add(Step(type: "transition", seconds: 10, id: nil, next: main[0].id, side: nil))
            var index = 0
            while true {
                let move = main[index % main.count]
                let length = move.eachSide ? 65 : 40
                let rest = 20
                guard used + length + rest <= mainEnd else { break }
                place(move, seconds: length, into: &steps, used: &used)
                let following = main[(index + 1) % main.count]
                let lapDone = (index + 1) % main.count == 0
                add(Step(type: lapDone ? "roundRest" : "rest", seconds: rest, id: nil, next: following.id, side: nil))
                index += 1
            }
        }

        // Cool-down: the last move (breathing) always closes the session; the others fit in the time left.
        // Then any seconds left go to the last move, so it ends exactly on time.
        // The last rest before the cool-down names the cool-down's first move.
        if let lastRest = steps.lastIndex(where: { $0.type == "rest" || $0.type == "roundRest" }), lastRest == steps.count - 1,
           let first = pools.coolDown.first {
            let rest = steps[lastRest]
            steps[lastRest] = Step(type: "rest", seconds: rest.seconds, id: nil, next: first.id, side: nil)
        }
        let coolStart = steps.count
        if let final = pools.coolDown.last {
            let length = { (move: Move) in move.eachSide ? 50 : 30 }
            var chosen: [Move] = []
            var planned = length(final)
            for move in pools.coolDown.dropLast() {
                let cost = length(move) + 5
                if used + planned + cost <= total {
                    chosen.append(move)
                    planned += cost
                }
            }
            chosen.append(final)
            for (i, move) in chosen.enumerated() {
                if i > 0 { add(Step(type: "rest", seconds: 5, id: nil, next: move.id, side: nil)) }
                place(move, seconds: length(move), into: &steps, used: &used)
            }
        }
        // Spread any seconds left over the cool-down holds, so no single stretch runs long.
        let holds = steps.indices.filter { $0 >= coolStart && steps[$0].type == "move" }
        if used < total, !holds.isEmpty {
            let extra = total - used
            for (n, i) in holds.enumerated() {
                let share = extra / holds.count + (n < extra % holds.count ? 1 : 0)
                let step = steps[i]
                steps[i] = Step(type: step.type, seconds: step.seconds + share, id: step.id, next: step.next, side: step.side)
            }
            used = total
        } else if used < total, let last = steps.lastIndex(where: { $0.type == "move" }) {
            let step = steps[last]
            steps[last] = Step(type: step.type, seconds: step.seconds + (total - used), id: step.id, next: step.next, side: step.side)
            used = total
        }
        return steps
    }

    /// Places a move; a move done on each side is split with a switch. Returns the seconds used.
    @discardableResult
    private static func place(_ move: Move, seconds: Int, into steps: inout [Step], used: inout Int) -> Int {
        if move.eachSide {
            let half = (seconds - 5) / 2
            steps.append(Step(type: "move", seconds: half, id: move.id, next: nil, side: "left"))
            steps.append(Step(type: "switch", seconds: 5, id: nil, next: move.id, side: nil))
            steps.append(Step(type: "move", seconds: seconds - 5 - half, id: move.id, next: nil, side: "right"))
        } else {
            steps.append(Step(type: "move", seconds: seconds, id: move.id, next: nil, side: nil))
        }
        used += seconds
        return seconds
    }
}

/// A small repeatable shuffle, so "Another one" gives a different mix and tests are stable.
struct SeededRandom {
    private var state: UInt64

    init(seed: Int) {
        state = UInt64(truncatingIfNeeded: seed) &* 6364136223846793005 &+ 1442695040888963407
    }

    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state >> 33
    }

    mutating func shuffled<T>(_ items: [T]) -> [T] {
        var out = items
        guard out.count > 1 else { return out }
        for i in stride(from: out.count - 1, to: 0, by: -1) {
            let j = Int(next() % UInt64(i + 1))
            out.swapAt(i, j)
        }
        return out
    }
}
