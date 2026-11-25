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
        Stretch(id: "childs-pose", name: "Child's pose",
                cues: ["Knees wide, big toes together, sit back on your heels.", "Reach your arms forward and let your forehead rest down."],
                eachSide: false),
        Stretch(id: "hamstring-fold", name: "Standing hamstring fold",
                cues: ["Feet hip-width, knees soft.", "Fold from the hips and let your head hang. Don't bounce."],
                eachSide: false),
        Stretch(id: "seated-fold", name: "Seated forward fold",
                cues: ["Sit with legs straight out, knees soft.", "Lengthen your spine first, then fold from the hips."],
                eachSide: false),
        Stretch(id: "figure-four", name: "Figure-four stretch",
                cues: ["On your back, cross one ankle over the opposite knee.", "Pull the bottom leg toward you until you feel the outer hip."],
                eachSide: true),
        Stretch(id: "supine-twist", name: "Supine twist",
                cues: ["On your back, hug one knee in, then let it fall across your body.", "Both shoulders stay on the floor."],
                eachSide: true),
        Stretch(id: "thread-needle", name: "Thread the needle",
                cues: ["From hands and knees, slide one arm under your chest.", "Rest your shoulder and ear down; keep your hips over your knees."],
                eachSide: true),
        Stretch(id: "puppy", name: "Puppy pose",
                cues: ["From hands and knees, walk your hands forward and lower your chest.", "Hips stay over your knees. Let your upper back melt down."],
                eachSide: false),
        Stretch(id: "cross-shoulder", name: "Cross-body shoulder stretch",
                cues: ["Bring one arm across your chest.", "Hold it above the elbow with the other hand. Shoulder stays down."],
                eachSide: true),
        Stretch(id: "quad-stretch", name: "Standing quad stretch",
                cues: ["Hold a wall, grab one ankle behind you.", "Knees side by side, hips pressed forward."],
                eachSide: true),
        Stretch(id: "calf-wall", name: "Calf stretch at a wall",
                cues: ["Hands on a wall, one foot back, heel down.", "Lean in with the back leg straight."],
                eachSide: true),
        Stretch(id: "downward-dog", name: "Downward dog",
                cues: ["From hands and knees, lift your hips up and back.", "Press the floor away. Bend your knees if your back rounds."],
                eachSide: false),
        Stretch(id: "low-lunge", name: "Low lunge",
                cues: ["One foot forward between your hands, back knee down.", "Sink your hips forward and lift your chest."],
                eachSide: true),
        Stretch(id: "sphinx", name: "Sphinx",
                cues: ["Lie face down, forearms under your shoulders.", "Draw your chest forward and keep your lower back relaxed."],
                eachSide: false),
        Stretch(id: "bridge-pose", name: "Bridge",
                cues: ["On your back, feet flat, arms by your sides.", "Lift your hips and roll your shoulders under. Keep your knees in line with your feet."],
                eachSide: false),
    ]

    // MARK: Hourly on weekdays (item 20)

    /// The default window: on the hour from 9 a.m. to the 5 p.m. stretch.
    public static let defaultStartHour = 9
    public static let defaultEndHour = 17
    /// The hours the window can start and end on.
    public static let windowHours = 6...21
    /// With a program running, an hour that has a set's bell this close gets no reminder: the stretch comes
    /// right after that set is logged instead (decision of 25 Nov 2026). An hour with no set near it keeps its
    /// reminder on the hour, as it does with no program.
    public static let setClearanceMinutes = 30
    /// At most this many hourly reminders are scheduled at once (about a working day); more are added on refill.
    public static let hourlyLimit = 10
    /// iOS keeps at most 64 pending notifications per app.
    public static let systemNotificationLimit = 64

    /// A start and end the app can use: both inside `windowHours`, and the end not before the start.
    public static func window(start: Int, end: Int) -> (start: Int, end: Int) {
        let s = min(max(start, windowHours.lowerBound), windowHours.upperBound)
        let e = min(max(end, s), windowHours.upperBound)
        return (s, e)
    }

    /// Monday to Friday.
    public static func isWeekday(_ date: CivilDate) -> Bool {
        // 1 Jan 2000, day number 0, was a Saturday.
        let weekday = ((date.dayNumber % 7) + 7) % 7
        return (2...6).contains(weekday)
    }

    /// Set alerts and hourly reminders share what the four note slots leave, less one kept spare for the stretch
    /// after a set or a test alert: 59 in all. The soonest win, whichever kind they are, so a reminder this
    /// afternoon goes ahead of a set alert tomorrow and neither crowds out the other for long. With no reminders
    /// wanted, set alerts keep all 60 of theirs. Both lists must be soonest first.
    public static func sharedSlots(setAlerts: [CivilDateTime], reminders: [CivilDateTime],
                                   setCapacity: Int = AlertQueue.capacity) -> (sets: Int, reminders: Int) {
        guard !reminders.isEmpty else { return (min(setAlerts.count, setCapacity), 0) }
        let total = systemNotificationLimit - 4 - 1
        var sets = 0
        var kept = 0
        while sets + kept < total {
            let nextSet = sets < min(setAlerts.count, setCapacity) ? setAlerts[sets] : nil
            let nextReminder = kept < min(reminders.count, hourlyLimit) ? reminders[kept] : nil
            switch (nextSet, nextReminder) {
            case let (s?, r?):
                if s <= r { sets += 1 } else { kept += 1 }
            case (_?, nil):
                sets += 1
            case (nil, _?):
                kept += 1
            case (nil, nil):
                return (sets, kept)
            }
        }
        return (sets, kept)
    }

    /// The hours to remind at, soonest first: weekdays only, on the hour inside the window, after `now`,
    /// skipping an hour when a set's bell is within 30 minutes (that set brings the stretch) or a stretch was done in
    /// the hour before it.
    public static func hourlySlots(after now: CivilDateTime, start: Int, end: Int, setAlerts: [CivilDateTime],
                                   lastDone: CivilDateTime?, limit: Int, daysAhead: Int = 3) -> [CivilDateTime] {
        guard limit > 0 else { return [] }
        let window = window(start: start, end: end)
        var slots: [CivilDateTime] = []
        for offset in 0...daysAhead {
            let date = now.date.addingDays(offset)
            guard isWeekday(date) else { continue }
            for hour in window.start...window.end {
                let slot = CivilDateTime(date: date, hour: hour, minute: 0)
                guard slot > now else { continue }
                if let lastDone, lastDone <= slot, lastDone.minutes(until: slot) < minimumGapMinutes { continue }
                if setAlerts.contains(where: { abs(slot.minutes(until: $0)) <= setClearanceMinutes }) { continue }
                slots.append(slot)
                if slots.count == limit { return slots }
            }
        }
        return slots
    }

    /// The stretch for an hour: it steps through all of them hour by hour, so every stretch comes up within a
    /// couple of working days, and a refill mostly keeps the reminders already scheduled.
    public static func stretchIndex(for slot: CivilDateTime) -> Int {
        let hourNumber = slot.date.dayNumber * 24 + slot.minutes / 60
        return ((hourNumber % all.count) + all.count) % all.count
    }

    /// The stretches for a run of reminders. Where a skipped hour would bring the same stretch twice in a row,
    /// or repeat the one before (the last reminder already delivered, or the last stretch shown), the next one is
    /// used instead, so a stretch never comes back to back.
    public static func stretchIndices(for slots: [CivilDateTime], previous: Int?) -> [Int] {
        var last = previous
        return slots.map { slot in
            var index = stretchIndex(for: slot)
            if index == last { index = (index + 1) % all.count }
            last = index
            return index
        }
    }

    /// Whether a stretch is due after a set logged now.
    public static func isDue(enabled: Bool, lastShown: CivilDateTime?, now: CivilDateTime) -> Bool {
        guard enabled else { return false }
        guard let lastShown else { return true }
        return lastShown.minutes(until: now) >= minimumGapMinutes
    }

    /// The next stretch: a shuffled bag of every stretch, so all of them come up before any repeats,
    /// and never the same one twice in a row across bags. Returns the stretch and the bag left over.
    public static func next<R: RandomNumberGenerator>(bag: [Int], last: Int?, using random: inout R) -> (index: Int, bag: [Int]) {
        var bag = bag.filter { all.indices.contains($0) }
        if bag.isEmpty {
            bag = Array(all.indices).shuffled(using: &random)
            // A new bag never starts with the one just shown.
            if bag.count > 1, bag.first == last { bag.swapAt(0, bag.count - 1) }
        }
        let index = bag.removeFirst()
        return (index, bag)
    }

    /// The stretch a reminder was for, from its id.
    public static func stretch(id: String) -> Stretch? {
        all.first { $0.id == id }
    }

    /// The steps of one stretch, after the person taps Start.
    public enum PhaseKind: Equatable, Sendable {
        case getInPosition
        case hold(side: String?)
        case switchSides
    }

    public struct Phase: Equatable, Sendable {
        public let kind: PhaseKind
        public let seconds: Int
    }

    public static let getReadySeconds = 5
    public static let perSideSeconds = 20
    public static let switchSeconds = 5

    /// Get into position, then hold. A stretch done on each side holds each side on its own, with a switch between.
    public static func phases(_ stretch: Stretch) -> [Phase] {
        if stretch.eachSide {
            return [
                Phase(kind: .getInPosition, seconds: getReadySeconds),
                Phase(kind: .hold(side: "left"), seconds: perSideSeconds),
                Phase(kind: .switchSides, seconds: switchSeconds),
                Phase(kind: .hold(side: "right"), seconds: perSideSeconds),
            ]
        }
        return [
            Phase(kind: .getInPosition, seconds: getReadySeconds),
            Phase(kind: .hold(side: nil), seconds: seconds),
        ]
    }

    /// The line under the timer for a stretch done on both sides.
    public static func sideNote(_ stretch: Stretch) -> String? {
        stretch.eachSide ? Copy.eachSideNote(seconds: perSideSeconds) : nil
    }
}

extension DeskStretch.Stretch: Identifiable {}
