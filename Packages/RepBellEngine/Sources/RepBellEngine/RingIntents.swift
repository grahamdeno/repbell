#if canImport(AppIntents) && os(iOS)
import AppIntents

/// What a button on a Rep Bell alarm asks the app to do.
public enum RingAction: Sendable {
    case quietNext
    case gotIt
    case startTheDay
}

/// The alarm buttons' intents. They live in the engine so both the app and the widget extension include them,
/// as AlarmKit needs. The app sets `handler` at launch; the system runs these in the app's process.
public enum RingIntents {
    nonisolated(unsafe) public static var handler: (@Sendable (RingAction) async -> Void)?
}

/// "Quiet next" on a ringing set alarm.
public struct QuietNextIntent: LiveActivityIntent {
    public static let title: LocalizedStringResource = "Quiet next"
    public static let openAppWhenRun: Bool = false
    public init() {}
    public func perform() async throws -> some IntentResult {
        await RingIntents.handler?(.quietNext)
        return .result()
    }
}

/// "Got it" on a ringing set alarm or the morning alarm.
public struct GotItIntent: LiveActivityIntent {
    public static let title: LocalizedStringResource = "Got it"
    public static let openAppWhenRun: Bool = false
    public init() {}
    public func perform() async throws -> some IntentResult {
        await RingIntents.handler?(.gotIt)
        return .result()
    }
}

/// "Start the day" on the morning alarm: opens Rep Bell to the day-start screen.
public struct StartTheDayIntent: LiveActivityIntent {
    public static let title: LocalizedStringResource = "Start the day"
    public static let openAppWhenRun: Bool = true
    public init() {}
    public func perform() async throws -> some IntentResult {
        await RingIntents.handler?(.startTheDay)
        return .result()
    }
}
#endif
