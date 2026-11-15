import Foundation
import XCTest
@testable import BreakClock

final class UniversalPollTests: XCTestCase {
    func testReplacementMidnightAndTies() {
        let start = Date(timeIntervalSince1970: 86400)
        let next = start.addingTimeInterval(86400)
        var election = UniversalPoll(now: start)
        election.ballots["user1"] = 1
        election.ballots["user1"] = 2
        XCTAssertEqual(election.count(1), 0)
        XCTAssertEqual(election.count(2), 1)
        XCTAssertEqual(election.slot(at: next.addingTimeInterval(-1)), 0)
        election.advance(to: next)
        XCTAssertEqual(election.current, 2)
        election.ballots["user2"] = 1
        XCTAssertEqual(election.slot(at: next.addingTimeInterval(86400)), 2)
        election.ballots["user3"] = 1
        XCTAssertEqual(election.slot(at: next.addingTimeInterval(86400)), 1)
        let clock = BreakClock(zone: TimeZone(secondsFromGMT: 0)!, hour: UniversalPoll.slots[election.current])
        XCTAssertNotNil(clock.active(at: next.addingTimeInterval(17 * 3600)))
        XCTAssertNil(clock.active(at: next.addingTimeInterval(18 * 3600)))
    }
}
