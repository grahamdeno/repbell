/// Desk stretch (1.0, added 20 Nov 2026): after a push-up set, one short stretch that counters sitting all day.
/// Off by default. Shown at most once an hour. Skipping is never recorded.
public enum DeskStretch {
    public struct Stretch: Equatable, Sendable {
        public let id: String
        public let name: String
        public let cues: [String]
        /// Stretches done on each side switch halfway.
        public let eachSide: Bool
    }

    public static let seconds = 30
    public static let minimumGapMinutes = 60

    /// The rotation, taken from the Workouts movements so names and cues match.
    public static let all: [Stretch] = [
        Stretch(id: "hip-flexor", name: "Kneeling hip flexor stretch",
                cues: ["Kneel on one knee, other foot forward.", "Squeeze the glute of the back leg and shift your hips forward."],
                eachSide: true),
        Stretch(id: "doorway-chest", name: "Doorway chest stretch",
                cues: ["Forearms on a doorframe, elbows at shoulder height.", "Step one foot through until you feel the chest open."],
                eachSide: false),
        Stretch(id: "neck-stretch", name: "Neck side stretch",
                cues: ["Sit or stand tall, tip your ear toward your shoulder.", "Let the opposite shoulder drop. No pulling on your head."],
                eachSide: true),
        Stretch(id: "wall-chest", name: "Chest opener at a wall",
                cues: ["Forearm on a wall at shoulder height.", "Turn your body away slowly until you feel the front of your shoulder."],
                eachSide: true),
        Stretch(id: "seated-hamstring", name: "Seated hamstring stretch",
                cues: ["Sit with one leg straight, the other foot against the inner thigh.", "Fold toward the straight leg with a long back."],
                eachSide: true),
    ]

    /// Whether a stretch is due after a set logged now.
    public static func isDue(enabled: Bool, lastShown: CivilDateTime?, now: CivilDateTime) -> Bool {
        guard enabled else { return false }
        guard let lastShown else { return true }
        return lastShown.minutes(until: now) >= minimumGapMinutes
    }

    /// The next stretch in the rotation.
    public static func next(after index: Int?) -> (index: Int, stretch: Stretch) {
        let i = ((index ?? -1) + 1) % all.count
        return (i, all[i])
    }

    /// The line under the timer for a stretch done on both sides.
    public static func sideNote(_ stretch: Stretch) -> String? {
        stretch.eachSide ? "Switch sides at \(seconds / 2) seconds." : nil
    }
}
