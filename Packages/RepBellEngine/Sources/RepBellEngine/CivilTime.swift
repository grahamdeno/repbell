import Foundation

/// A clock time on the waking day. Midnight (`0:00`) is the end of the day when it is not after wake.
public struct ClockTime: Hashable, Codable, Sendable, Equatable {
    public var hour: Int
    public var minute: Int

    public init(hour: Int, minute: Int = 0) {
        self.hour = hour
        self.minute = minute
    }

    public var minutesFromMidnight: Int { hour * 60 + minute }
}

/// A calendar day in local civil time. The engine never stores instants, so a time-zone change recomputes in local time.
public struct CivilDate: Hashable, Codable, Sendable, Comparable {
    public var year: Int
    public var month: Int
    public var day: Int

    public init(year: Int, month: Int, day: Int) {
        self.year = year
        self.month = month
        self.day = day
    }

    public static func < (lhs: CivilDate, rhs: CivilDate) -> Bool {
        if lhs.year != rhs.year { return lhs.year < rhs.year }
        if lhs.month != rhs.month { return lhs.month < rhs.month }
        return lhs.day < rhs.day
    }

    public func addingDays(_ count: Int) -> CivilDate {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let base = calendar.date(from: DateComponents(year: year, month: month, day: day))!
        let shifted = calendar.date(byAdding: .day, value: count, to: base)!
        let parts = calendar.dateComponents([.year, .month, .day], from: shifted)
        return CivilDate(year: parts.year!, month: parts.month!, day: parts.day!)
    }

    /// Days since 2000-01-01, for gaps that cross midnight.
    public var dayNumber: Int {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let epoch = calendar.date(from: DateComponents(year: 2000, month: 1, day: 1))!
        let date = calendar.date(from: DateComponents(year: year, month: month, day: day))!
        return calendar.dateComponents([.day], from: epoch, to: date).day!
    }
}

/// A local civil date and minute-of-day. Minutes outside `0..<1440` roll into the neighboring date.
public struct CivilDateTime: Hashable, Codable, Sendable, Comparable {
    public var date: CivilDate
    public var minutes: Int

    public init(date: CivilDate, hour: Int, minute: Int) {
        self.date = date
        self.minutes = hour * 60 + minute
        normalize()
    }

    public init(date: CivilDate, minutes: Int) {
        self.date = date
        self.minutes = minutes
        normalize()
    }

    public static func < (lhs: CivilDateTime, rhs: CivilDateTime) -> Bool {
        if lhs.date != rhs.date { return lhs.date < rhs.date }
        return lhs.minutes < rhs.minutes
    }

    public func adding(minutes delta: Int) -> CivilDateTime {
        CivilDateTime(date: date, minutes: minutes + delta)
    }

    public func minutes(until other: CivilDateTime) -> Int {
        (other.date.dayNumber - date.dayNumber) * 1440 + (other.minutes - minutes)
    }

    public var absoluteMinutes: Int { date.dayNumber * 1440 + minutes }

    /// Local components from `date`. Seconds are dropped; the schedule lives on the minute.
    public static func local(_ date: Date, calendar: Calendar = .current) -> CivilDateTime {
        let parts = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        return CivilDateTime(
            date: CivilDate(year: parts.year!, month: parts.month!, day: parts.day!),
            hour: parts.hour!,
            minute: parts.minute!
        )
    }

    public func foundationDate(calendar: Calendar = .current) -> Date? {
        calendar.date(
            from: DateComponents(
                year: date.year,
                month: date.month,
                day: date.day,
                hour: minutes / 60,
                minute: minutes % 60
            )
        )
    }

    private mutating func normalize() {
        var shift = 0
        var value = minutes
        while value >= 1440 {
            value -= 1440
            shift += 1
        }
        while value < 0 {
            value += 1440
            shift -= 1
        }
        minutes = value
        if shift != 0 {
            date = date.addingDays(shift)
        }
    }
}
