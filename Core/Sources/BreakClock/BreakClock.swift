import Foundation

public struct BreakClock {
    public var zone: TimeZone
    public var hour: Int

    public init(zone: TimeZone, hour: Int = 14) {
        self.zone = zone
        self.hour = hour
    }

    /// The community opens at the first instant and closes at the end of the hour.
    public func active(at now: Date) -> DateInterval? {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = zone
        guard let start = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: now)
        else { return nil }
        let end = start.addingTimeInterval(3600)
        return now >= start && now < end ? DateInterval(start: start, end: end) : nil
    }

    public func isLocked(at now: Date, peerTesting: Bool, manualLock: Bool) -> Bool {
        if peerTesting { return manualLock }
        return active(at: now) == nil
    }
}
