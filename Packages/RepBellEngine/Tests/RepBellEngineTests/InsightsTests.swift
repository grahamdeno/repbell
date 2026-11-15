import XCTest
@testable import RepBellEngine

final class InsightsTests: XCTestCase {
    private let start = CivilDate(year: 2026, month: 11, day: 16)

    private func at(day: Int, _ hour: Int, _ minute: Int) -> CivilDateTime {
        CivilDateTime(date: start.addingDays(day - 1), hour: hour, minute: minute)
    }

    private func input(_ events: [LogEvent]) -> RunInput {
        RunInput(dayOneMax: 0, wake: ClockTime(hour: 7), bed: ClockTime(hour: 23), start: start, events: events)
    }

    func testGainAcrossTests() {
        let run = input([
            .test(day: 1, reps: 40, at: at(day: 1, 7, 5)),
            .test(day: 8, reps: 50, at: at(day: 8, 7, 5)),
        ])
        let insights = InsightsEngine.run(run, now: at(day: 8, 8, 0))
        XCTAssertEqual(insights.maxes.map(\.reps), [40, 50])
        XCTAssertEqual(insights.gainPercent, 25)
        XCTAssertTrue(insights.observations.contains { $0.text.contains("25%") })
    }

    func testResponseTimeAndOnTime() {
        let resolved = ScheduleEngine.resolve(input([.test(day: 1, reps: 40, at: at(day: 1, 7, 5))]), now: at(day: 2, 7, 0))
        let sets = resolved.day(2)!.sets
        let first = sets[0].grid, second = sets[1].grid
        let run = input([
            .test(day: 1, reps: 40, at: at(day: 1, 7, 5)),
            .done(day: 2, index: sets[0].index, at: CivilDateTime(date: first.date, minutes: first.minutes + 2)),
            .done(day: 2, index: sets[1].index, at: CivilDateTime(date: second.date, minutes: second.minutes + 30)),
            .snooze(day: 2, index: sets[2].index, at: sets[2].grid),
        ])
        let insights = InsightsEngine.run(run, now: CivilDateTime(date: second.date, minutes: second.minutes + 31))
        XCTAssertEqual(insights.onTimePercent, 50)
        XCTAssertEqual(insights.medianResponseMinutes, 16)
        XCTAssertEqual(insights.snoozes, 1)
    }

    func testWindowPreviewShortensTheDay() {
        let run = input([.test(day: 1, reps: 40, at: at(day: 1, 7, 5))])
        let preview = ScheduleEngine.previewWindowChange(run, wake: ClockTime(hour: 7), bed: ClockTime(hour: 21), at: at(day: 2, 12, 5))
        XCTAssertGreaterThan(preview.before, preview.after)
        XCTAssertNotNil(preview.last)
    }
}
