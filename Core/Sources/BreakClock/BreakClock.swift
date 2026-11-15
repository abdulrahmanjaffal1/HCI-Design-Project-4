import Foundation

public struct BreakClock {
    public var zone: TimeZone
    public var demoStart: Date?

    public var hour: Int

    public init(zone: TimeZone, demoStart: Date? = nil, hour: Int = 14) {
        self.zone = zone
        self.hour = hour
        self.demoStart = demoStart
    }

    /// A half-open interval. At exactly the end, all protected screens reopen.
    public func active(at now: Date) -> DateInterval? {
        let interval: DateInterval
        if let start = demoStart {
            interval = DateInterval(start: start.addingTimeInterval(20), duration: 60)
        } else {
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = zone
            guard let start = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: now),
                  let end = calendar.date(bySettingHour: hour + 1, minute: 0, second: 0, of: now)
            else { return nil }
            interval = DateInterval(start: start, end: end)
        }
        return now >= interval.start && now < interval.end ? interval : nil
    }
}
