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

    /// Whether a program day can be used. With payment off (1.0) every day of every run is open.
    public func allows(day: Int) -> Bool {
        guard Features.payment else { return true }
        if unlocked { return true }
        if isFirstRun && (1...3).contains(day) { return true }
        return false
    }

    /// Whether the app must ask for the unlock before showing the current run at this moment.
    /// Always false while payment is off.
    public func needsUnlock(at now: CivilDateTime) -> Bool {
        guard Features.payment, let current, !current.ended else { return false }
        if !unlocked && !isFirstRun { return true }
        let moment = current.pausedAt ?? now
        if current.pausedAt == nil, let number = current.input.dayNumber(on: moment.date), !allows(day: number) {
            return true
        }
        return false
    }

    /// Whether starting another run needs the unlock. Always false while payment is off.
    public var rerunNeedsUnlock: Bool { Features.payment && !unlocked }

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
