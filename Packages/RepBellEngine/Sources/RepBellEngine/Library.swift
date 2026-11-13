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

    public var isFirstRun: Bool { runsStarted <= 1 }

    /// Days 1 to 3 of the first run are free. Everything else needs the one-time unlock.
    public func allows(day: Int) -> Bool {
        if unlocked { return true }
        if isFirstRun && (1...3).contains(day) { return true }
        return false
    }

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
