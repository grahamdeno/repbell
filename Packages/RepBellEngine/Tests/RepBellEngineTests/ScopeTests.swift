import XCTest
@testable import RepBellEngine

/// Roadmap items 1 and 4: what 1.0 is. Workouts in, coach clips in for testing, payment off, nothing locked.
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

    // Item 4: payment is off in 1.0.
    func testItem4_paymentIsOff() {
        XCTAssertFalse(Features.payment)
    }

    // Item 4: every day of the first run opens without a purchase.
    func testItem4_everyDayOfFirstRunIsOpen() {
        let library = LibraryFile(runsStarted: 1, unlocked: false, current: run())
        for day in 1...15 {
            XCTAssertTrue(library.allows(day: day), "Day \(day) should be open")
        }
    }

    // Item 4: a rerun opens without a purchase, and starting one never asks for the unlock.
    func testItem4_rerunsAreOpen() {
        let library = LibraryFile(runsStarted: 4, unlocked: false, current: run())
        for day in 1...15 {
            XCTAssertTrue(library.allows(day: day), "Rerun day \(day) should be open")
        }
        XCTAssertFalse(library.rerunNeedsUnlock)
    }

    // Item 4: no route leads to the paywall, on any day, first run or rerun, running or paused.
    func testItem4_paywallNeverRequired() {
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

    // Item 4: no copy mentions free days or a price.
    func testItem4_noPriceOrFreeDayCopy() {
        let lines = [Copy.unlockTitle, Copy.unlockBody, Copy.unlockButton, Copy.unlockMissing, Copy.promiseBody]
        for line in lines {
            let lower = line.lowercased()
            XCTAssertFalse(lower.contains("$"), line)
            XCTAssertFalse(lower.contains("4.99"), line)
            XCTAssertFalse(lower.contains("free"), line)
            XCTAssertFalse(lower.contains("three days"), line)
        }
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
