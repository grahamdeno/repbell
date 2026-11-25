import Foundation

/// The on-device record. One current run, plus ended runs kept on the phone.
public struct PersistedRun: Equatable, Codable, Sendable {
    public var input: RunInput
    public var pausedAt: CivilDateTime?
    public var ended: Bool

    public init(input: RunInput, pausedAt: CivilDateTime? = nil, ended: Bool = false) {
        self.input = input
        self.pausedAt = pausedAt
        self.ended = ended
    }

    private enum CodingKeys: String, CodingKey { case input, pausedAt, ended }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        input = try c.decode(RunInput.self, forKey: .input)
        pausedAt = try c.decodeIfPresent(CivilDateTime.self, forKey: .pausedAt)
        ended = try c.decodeIfPresent(Bool.self, forKey: .ended) ?? false
    }
}

public struct LibraryFile: Equatable, Codable, Sendable {
    public static let appGroup = "group.com.grahamdeno.repbell"
    public static let fileName = "library.json"
    public static let unlockProductID = "com.grahamdeno.repbell.unlock"

    public var runsStarted: Int
    public var unlocked: Bool
    public var current: PersistedRun?
    public var history: [PersistedRun]

    public init(runsStarted: Int = 0, unlocked: Bool = false, current: PersistedRun? = nil, history: [PersistedRun] = []) {
        self.runsStarted = runsStarted
        self.unlocked = unlocked
        self.current = current
        self.history = history
    }

    private enum CodingKeys: String, CodingKey { case runsStarted, unlocked, current, history }

    /// Missing fields decode with defaults, so a stored record is never lost.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        runsStarted = try c.decodeIfPresent(Int.self, forKey: .runsStarted) ?? 0
        unlocked = try c.decodeIfPresent(Bool.self, forKey: .unlocked) ?? false
        current = try c.decodeIfPresent(PersistedRun.self, forKey: .current)
        history = try c.decodeIfPresent([PersistedRun].self, forKey: .history) ?? []
    }

    public var isFirstRun: Bool { runsStarted <= 1 }

    /// The 14-day program is never locked: every day of every run is open (roadmap item 18).
    public func allows(day: Int) -> Bool { true }

    /// The program never asks for the unlock. Kept so stored runs and callers stay unchanged.
    public func needsUnlock(at now: CivilDateTime) -> Bool { false }

    /// Starting another run never needs the unlock.
    public var rerunNeedsUnlock: Bool { false }

    /// Whether Workouts and Coach voice are open: the unlock was bought or restored, or payment is switched off.
    public var paidFeaturesOpen: Bool { !Features.payment || unlocked }

    public func resolved(at now: CivilDateTime) -> ResolvedRun? {
        guard let current else { return nil }
        let moment = current.pausedAt ?? now
        return ScheduleEngine.resolve(current.input, now: moment)
    }
}

public enum LibraryDisk {
    public static func fileURL() -> URL {
        #if os(iOS) || os(watchOS) || os(macOS) || os(visionOS)
        let group = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: LibraryFile.appGroup)
        #else
        let group: URL? = nil
        #endif
        let base = group ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        return base.appendingPathComponent(LibraryFile.fileName)
    }

    public static func load() -> LibraryFile {
        guard let data = try? Data(contentsOf: fileURL()) else { return LibraryFile() }
        return (try? JSONDecoder().decode(LibraryFile.self, from: data)) ?? LibraryFile()
    }

    public static func save(_ library: LibraryFile) {
        guard let data = try? JSONEncoder().encode(library) else { return }
        try? data.write(to: fileURL(), options: .atomic)
    }
}
