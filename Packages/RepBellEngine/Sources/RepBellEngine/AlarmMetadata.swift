#if canImport(AlarmKit)
import AlarmKit

/// Shared by the iPhone app and the widget so AlarmKit can decode the test-morning alarm.
public struct RepBellAlarmMetadata: AlarmMetadata {
    public var day: Int

    public init(day: Int) {
        self.day = day
    }
}
#endif
