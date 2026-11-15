import Foundation

/// Ballots are standing preferences. Today's schedule freezes at midnight UTC.
public struct UniversalPoll: Codable {
    public static let slots = [14, 15, 17]
    public var ballots: [String: Int] = [:]
    public private(set) var current = 0
    private var lastDay: Int
    public init(now: Date = Date()) { lastDay = Self.day(now) }
    public static func day(_ date: Date) -> Int { Int(floor(date.timeIntervalSince1970 / 86400)) }
    public func count(_ slot: Int) -> Int { ballots.values.filter { $0 == slot }.count }
    public func slot(at date: Date) -> Int {
        guard Self.day(date) > lastDay else { return current }
        let best = Self.slots.indices.map(count).max() ?? 0
        return count(current) == best ? current : Self.slots.indices.first { count($0) == best } ?? current
    }
    public mutating func advance(to date: Date) {
        guard Self.day(date) > lastDay else { return }
        current = slot(at: date)
        lastDay = Self.day(date)
    }
}
