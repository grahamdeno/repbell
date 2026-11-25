import XCTest
@testable import RepBellEngine

/// Roadmap items 1 and 18: what 1.0 is. The program is free; Workouts and Coach voice need the unlock;
/// coach clips are in for testing.
final class ScopeTests: XCTestCase {
    private let start = CivilDate(year: 2026, month: 11, day: 16)

    private func run(ended: Bool = false, pausedAt: CivilDateTime? = nil) -> PersistedRun {
        PersistedRun(
            input: RunInput(dayOneMax: 40, wake: ClockTime(hour: 7), bed: ClockTime(hour: 23), start: start),
            pausedAt: pausedAt,
            ended: ended
        )
    }

    // Item 1: Workouts is switched on by a build setting. Coach clips are in for TestFlight testing
    // (decision of 23 Nov 2026); R-1 is met or this flips back before any ship go.
    func testItem1_workoutsOnByBuildSettingAndCoachClipsInForTesting() {
        XCTAssertTrue(Features.workouts)
        XCTAssertTrue(Features.coachMedia)
    }

    // xAI asks that Grok output be attributed; the credit names Grok in its accepted wording.
    func testCoachCreditNamesGrok() {
        XCTAssertTrue(Copy.coachCredit.lowercased().contains("created with grok"))
        XCTAssertFalse(Copy.coachCredit.contains("!"))
    }

    // Item 18: payment is on; Workouts and Coach voice need the unlock.
    func testItem18_paymentIsOn() {
        XCTAssertTrue(Features.payment)
    }

    // Item 18: every day of every run opens without a purchase.
    func testItem18_programIsNeverLocked() {
        for runsStarted in [0, 1, 2, 5] {
            let library = LibraryFile(runsStarted: runsStarted, unlocked: false, current: run())
            for day in 1...15 {
                XCTAssertTrue(library.allows(day: day), "runs \(runsStarted), day \(day)")
            }
            XCTAssertFalse(library.rerunNeedsUnlock)
        }
    }

    // Item 18: no route through the program leads to the paywall, running or paused.
    func testItem18_programNeverNeedsUnlock() {
        for runsStarted in [0, 1, 2, 5] {
            for offset in 0...16 {
                let now = CivilDateTime(date: start.addingDays(offset), hour: 12, minute: 0)
                let running = LibraryFile(runsStarted: runsStarted, unlocked: false, current: run())
                let paused = LibraryFile(runsStarted: runsStarted, unlocked: false, current: run(pausedAt: now))
                XCTAssertFalse(running.needsUnlock(at: now), "runs \(runsStarted), offset \(offset)")
                XCTAssertFalse(paused.needsUnlock(at: now), "paused, runs \(runsStarted), offset \(offset)")
            }
        }
    }

    // Item 18: Workouts and Coach voice open only with the unlock.
    func testItem18_paidFeaturesNeedTheUnlock() {
        XCTAssertFalse(LibraryFile(runsStarted: 1, unlocked: false).paidFeaturesOpen)
        XCTAssertTrue(LibraryFile(runsStarted: 1, unlocked: true).paidFeaturesOpen)
    }

    // Item 18: Coach voice is Off without the unlock, whatever was chosen.
    func testItem18_coachVoiceNeedsTheUnlock() {
        for mode in CoachMode.allCases {
            XCTAssertEqual(CoachMode.effective(stored: mode, paidFeaturesOpen: false), .off)
            XCTAssertEqual(CoachMode.effective(stored: mode, paidFeaturesOpen: true), mode)
        }
    }

    // Item 18: the price comes from the store, never from copy; no free-day wording; no exclamation marks.
    func testItem18_unlockCopyHasNoPriceOrFreeDays() {
        let lines = [Copy.unlockTitle, Copy.unlockBody, Copy.unlockButton, Copy.unlockMissing, Copy.unlockWorkouts,
                     Copy.unlockCoach, Copy.unlockPending, Copy.unlockFailed, Copy.unlockDone, Copy.notNow,
                     Copy.promiseBody]
        for line in lines {
            let lower = line.lowercased()
            XCTAssertFalse(lower.contains("$"), line)
            XCTAssertFalse(lower.contains("4.99"), line)
            XCTAssertFalse(lower.contains("free"), line)
            XCTAssertFalse(lower.contains("three days"), line)
            XCTAssertFalse(line.contains("!"), line)
        }
        XCTAssertEqual(Copy.unlockButton(price: "$4.99"), "Unlock for $4.99")
    }

    // Data safety: a library saved by the first build (with `unlocked` and `runsStarted`) still decodes.
    func testStoredLibraryFromFirstBuildStillDecodes() throws {
        let json = """
        {"runsStarted":2,"unlocked":false,"history":[],"current":{"input":{"dayOneMax":40,"wake":{"hour":7,"minute":0},"bed":{"hour":23,"minute":0},"start":{"year":2026,"month":11,"day":16},"retestEnabled":true,"events":[{"done":{"day":1,"index":0,"at":{"date":{"year":2026,"month":11,"day":16},"minutes":480}}}],"shifts":[{"day":3,"minutes":1440}]},"ended":false}}
        """
        let library = try JSONDecoder().decode(LibraryFile.self, from: Data(json.utf8))
        XCTAssertEqual(library.runsStarted, 2)
        XCTAssertEqual(library.current?.input.dayOneMax, 40)
        XCTAssertEqual(library.current?.input.events.count, 1)
        XCTAssertEqual(library.current?.input.shifts.count, 1)
        XCTAssertTrue(library.allows(day: 9))
    }

    // Data safety: a record missing fields added later still loads with defaults, and round-trips.
    func testStoredLibraryWithMissingFieldsStillDecodes() throws {
        let json = """
        {"current":{"input":{"dayOneMax":40,"wake":{"hour":7,"minute":0},"bed":{"hour":23,"minute":0},"start":{"year":2026,"month":11,"day":16}}}}
        """
        let library = try JSONDecoder().decode(LibraryFile.self, from: Data(json.utf8))
        XCTAssertEqual(library.runsStarted, 0)
        XCTAssertEqual(library.history.count, 0)
        XCTAssertEqual(library.current?.ended, false)
        XCTAssertEqual(library.current?.input.retestEnabled, true)
        XCTAssertEqual(library.current?.input.events.count, 0)
        XCTAssertEqual(library.current?.input.shifts.count, 0)
        let again = try JSONDecoder().decode(LibraryFile.self, from: JSONEncoder().encode(library))
        XCTAssertEqual(again, library)
    }
}
