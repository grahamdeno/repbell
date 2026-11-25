import Foundation
import RepBellEngine
#if canImport(FoundationModels)
import FoundationModels
#endif

/// The person's Coach voice choice (roadmap item 17). Off by default.
enum CoachVoiceStore {
    static let key = "coach.mode"

    static var mode: CoachMode {
        get { CoachMode(rawValue: UserDefaults.standard.string(forKey: key) ?? "") ?? .off }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: key) }
    }
}

/// Writes a coach line with Apple's on-device model. Nothing leaves the phone, and the model sees numbers only.
enum CoachWriter {
    /// A generated line, or nil when the model is unavailable, takes too long, or breaks a rule.
    /// The caller shows the written line in that case.
    static func generated(mode: CoachMode, facts: CoachFacts, timeout: Double = 3) async -> String? {
        guard mode != .off else { return nil }
        #if canImport(FoundationModels)
        guard case .available = SystemLanguageModel.default.availability else { return nil }
        return await withTaskGroup(of: String?.self) { group in
            group.addTask {
                let session = LanguageModelSession(instructions: CoachVoice.instructions(mode: mode))
                let options = GenerationOptions(temperature: 0.8, maximumResponseTokens: 60)
                guard let response = try? await session.respond(to: CoachVoice.prompt(facts: facts), options: options) else {
                    return nil
                }
                let line = response.content
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .trimmingCharacters(in: CharacterSet(charactersIn: "\"“”"))
                return CoachVoice.accepts(line, mode: mode, facts: facts) ? line : nil
            }
            group.addTask {
                try? await Task.sleep(for: .seconds(timeout))
                return nil
            }
            let first = await group.next() ?? nil
            group.cancelAll()
            return first
        }
        #else
        return nil
        #endif
    }
}
