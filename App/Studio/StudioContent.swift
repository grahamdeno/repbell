import Foundation
import RepBellEngine

struct StudioMovement: Decodable, Identifiable, Hashable {
    let id: String
    let name: String
    let cues: [String]
    let sides: String
    let gear: [String]
    let standIn: String?
    let easier: String?
    let harder: String?
    let view: String
    let keyframes: [String]
    let modify: [String: String]
}

struct StudioStep: Decodable, Hashable {
    let type: String
    let seconds: Int
    let id: String?
    let next: String?
    let side: String?
    let pace: String?
    let role: String?

    var isMove: Bool { type == "move" }
}

struct StudioSession: Decodable, Identifiable, Hashable {
    let id: String
    let name: String
    let gear: [String]
    let free: Bool
    let minutes: Int
    let timeline: [StudioStep]

    /// Distinct moves in first-seen order, with the total time each one is worked.
    var outline: [(id: String, seconds: Int)] {
        var order: [String] = []
        var totals: [String: Int] = [:]
        for step in timeline where step.isMove {
            guard let id = step.id, step.role != "recovery" else { continue }
            if totals[id] == nil { order.append(id) }
            totals[id, default: 0] += step.seconds
        }
        return order.map { ($0, totals[$0] ?? 0) }
    }
}

private struct MovementFile: Decodable { let movements: [StudioMovement] }

private struct SessionFile: Decodable {
    let sessions: [StudioSession]
    let suggest: [String: [String]]
}

final class StudioLibrary {
    static let shared = StudioLibrary()

    let movements: [String: StudioMovement]
    let sessions: [StudioSession]
    let suggest: [String: [String]]
    /// The session last built by Fit my time.
    var fitted: StudioSession?

    private init() {
        let decoder = JSONDecoder()
        if let url = Bundle.main.url(forResource: "movements", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let file = try? decoder.decode(MovementFile.self, from: data) {
            movements = Dictionary(uniqueKeysWithValues: file.movements.map { ($0.id, $0) })
        } else {
            movements = [:]
        }
        if let url = Bundle.main.url(forResource: "sessions", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let file = try? decoder.decode(SessionFile.self, from: data) {
            sessions = file.sessions
            suggest = file.suggest
        } else {
            sessions = []
            suggest = [:]
        }
    }

    func session(_ id: String) -> StudioSession? {
        if id == FitMyTime.sessionID { return fitted }
        return sessions.first { $0.id == id }
    }

    /// Moves of the named sessions, past their shared warm-up and before their shared cool-down.
    private func mainMoves(of ids: [String]) -> [String] {
        var out: [String] = []
        for id in ids {
            guard let session = sessions.first(where: { $0.id == id }) else { continue }
            for item in session.outline where !FitMyTimePools.warmUp.contains(item.id) && !FitMyTimePools.coolDown.contains(item.id) {
                if !out.contains(item.id) { out.append(item.id) }
            }
        }
        return out
    }

    /// Builds a Fit my time session for the focus, the person's gear and the program rule, and keeps it.
    @MainActor
    func fit(minutes: Int, focus: FitMyTime.Focus, seed: Int, settings: StudioSettings, runActive: Bool) -> StudioSession {
        let sources: [String]
        switch focus {
        case .legs: sources = ["lower-back", "jump"]
        case .core: sources = ["core", "ab-finisher", "easy-cardio"]
        case .mobility: sources = ["stretch", "flow-45"]
        case .fullBody: sources = ["lower-back", "core", "upper", "easy-cardio"]
        }
        // During a run, moves from upper-body sessions stay out, even if they're also elsewhere.
        let held = runActive ? Set(mainMoves(of: Array(WorkoutRules.upperBody))) : []
        let usable = { (id: String) -> FitMyTime.Move? in
            guard let move = self.movements[id] else { return nil }
            let missing = move.gear.filter { $0 != "mat" && !settings.gear.contains($0) }
            if !missing.isEmpty && self.movements[move.standIn ?? ""] == nil { return nil }
            return FitMyTime.Move(id: id, eachSide: move.sides == "each")
        }
        // Lying-down closers aren't main moves, and planks and sun flows load the push-up muscles.
        let notMain: Set<String> = ["final-rest", "centering", "high-plank", "sun-flow-a", "sun-flow-b", "side-plank", "dolphin", "crow"]
        let main = mainMoves(of: sources).filter { !held.contains($0) && !notMain.contains($0) }.compactMap(usable)
        let pools = FitMyTime.Pools(
            warmUp: FitMyTimePools.warmUp.compactMap(usable),
            main: main,
            coolDown: FitMyTimePools.coolDown.compactMap(usable)
        )
        let steps = FitMyTime.build(minutes: minutes, pools: pools, seed: seed).map {
            StudioStep(type: $0.type, seconds: $0.seconds, id: $0.id, next: $0.next, side: $0.side, pace: nil, role: nil)
        }
        let session = StudioSession(id: FitMyTime.sessionID, name: StudioCopy.fitName(minutes), gear: [], free: true, minutes: minutes, timeline: steps)
        fitted = session
        return session
    }
    func movement(_ id: String?) -> StudioMovement? { id.flatMap { movements[$0] } }
}

/// The shared warm-up and cool-down moves every Workouts session uses.
enum FitMyTimePools {
    static let warmUp = ["march", "arm-circles", "hip-circles", "good-morning", "inchworm"]
    static let coolDown = ["childs-pose", "wall-chest", "hamstring-fold", "breathing"]
}

/// Studio settings and history, kept apart from the push-up library file.
@MainActor
@Observable
final class StudioSettings {
    static let shared = StudioSettings()

    nonisolated static let allGear = ["bar", "band", "kettlebell", "gi-bag", "balance-board", "rice-bucket", "chair", "table", "block", "strap"]
    nonisolated static let zones = ["knees", "lowerBack", "shoulders"]

    var mascot: String { didSet { save() } }
    var gear: Set<String> { didSet { save() } }
    var easyOn: Set<String> { didSet { save() } }
    /// Save finished sessions to Apple Health.
    var health: Bool { didSet { save() } }
    private(set) var log: [StudioLogEntry]

    private let defaults = UserDefaults.standard

    private init() {
        mascot = defaults.string(forKey: "studio.mascot") ?? "him"
        gear = Set(defaults.stringArray(forKey: "studio.gear") ?? ["chair", "table"])
        easyOn = Set(defaults.stringArray(forKey: "studio.easyOn") ?? [])
        health = defaults.bool(forKey: "studio.health")
        if let data = defaults.data(forKey: "studio.log"), let entries = try? JSONDecoder().decode([StudioLogEntry].self, from: data) {
            log = entries
        } else {
            log = []
        }
    }

    private func save() {
        defaults.set(mascot, forKey: "studio.mascot")
        defaults.set(Array(gear), forKey: "studio.gear")
        defaults.set(Array(easyOn), forKey: "studio.easyOn")
        defaults.set(health, forKey: "studio.health")
    }

    func record(session: StudioSession, seconds: Int) {
        log.append(StudioLogEntry(date: Date(), sessionID: session.id, name: session.name, minutes: max(1, seconds / 60)))
        if let data = try? JSONEncoder().encode(log) {
            defaults.set(data, forKey: "studio.log")
        }
    }

    /// Gear (other than a mat) a session needs that the person hasn't said they have.
    func missingGear(_ session: StudioSession) -> [String] {
        session.gear.filter { $0 != "mat" && !gear.contains($0) }
    }

    nonisolated static func zoneLabel(_ zone: String) -> String {
        switch zone {
        case "knees": return "Knees"
        case "lowerBack": return "Lower back"
        case "shoulders": return "Shoulders"
        default: return zone
        }
    }

    nonisolated static func gearLabel(_ gear: String) -> String {
        switch gear {
        case "bar": return "Pull-up bar"
        case "band": return "Bands or dumbbells"
        case "chair": return "Sturdy chair"
        case "table": return "Sturdy table"
        case "block": return "Yoga block"
        case "strap": return "Strap or towel"
        case "kettlebell": return "Kettlebell"
        case "gi-bag": return "Sandbag with a gi"
        case "balance-board": return "Balance board"
        case "rice-bucket": return "Bucket of rice"
        default: return gear.capitalized
        }
    }
}

struct StudioLogEntry: Codable, Hashable {
    var date: Date
    var sessionID: String
    var name: String
    var minutes: Int
}

/// Resolves what the player should actually show for a step, given the person's settings.
struct ResolvedMove {
    let movement: StudioMovement
    let cues: [String]
    let note: String?
}

extension StudioSettings {
    func resolve(_ id: String) -> ResolvedMove? {
        let library = StudioLibrary.shared
        guard var movement = library.movement(id) else { return nil }
        var note: String?
        // Missing gear: switch to the stand-in movement when there is one.
        let needs = movement.gear.filter { $0 != "mat" && !gear.contains($0) }
        if !needs.isEmpty, let stand = library.movement(movement.standIn) {
            note = "Using \(stand.name.lowercased()) instead"
            movement = stand
        }
        // Go easy on: take the first matching modification, else the easier movement.
        for zone in StudioSettings.zones where easyOn.contains(zone) {
            if let tip = movement.modify[zone] {
                return ResolvedMove(movement: movement, cues: [movement.cues.first ?? "", tip], note: note ?? "Easier for your \(StudioSettings.zoneLabel(zone).lowercased())")
            }
        }
        return ResolvedMove(movement: movement, cues: movement.cues, note: note)
    }
}

/// Workouts is switched by the build setting in `Features`, never by receipt type.
enum StudioFeature {
    static var enabled: Bool { Features.workouts }
}
