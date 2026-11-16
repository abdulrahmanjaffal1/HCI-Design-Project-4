import Foundation
import XCTest
@testable import BreakClock

final class ClockTests: XCTestCase {
    func instant(_ s: String) -> Date { ISO8601DateFormatter().date(from: s)! }
    func testBoundaries() {
        let clock = BreakClock(zone: TimeZone(identifier: "America/Chicago")!)
        for start in ["2026-03-08T19:00:00Z", "2026-11-01T20:00:00Z"] {
            let t = instant(start)
            XCTAssertNil(clock.active(at: t.addingTimeInterval(-1)))
            XCTAssertEqual(clock.active(at: t)?.end, t.addingTimeInterval(3600))
            XCTAssertNotNil(clock.active(at: t.addingTimeInterval(3599)))
            XCTAssertNil(clock.active(at: t.addingTimeInterval(3600)))
        }
    }
    func testRegion() {
        let t = instant("2026-11-13T19:30:00Z")
        XCTAssertNotNil(BreakClock(zone: TimeZone(identifier: "America/New_York")!).active(at: t))
        XCTAssertNil(BreakClock(zone: TimeZone(identifier: "America/Los_Angeles")!).active(at: t))
    }
    func testShowcaseAndScheduledAccess() {
        let clock = BreakClock(zone: TimeZone(secondsFromGMT: 0)!)
        let inside = instant("2026-11-13T14:30:00Z")
        let outside = instant("2026-11-13T15:00:00Z")
        for time in [inside, outside] {
            XCTAssertFalse(clock.isLocked(at: time, peerTesting: true, manualLock: false))
            XCTAssertTrue(clock.isLocked(at: time, peerTesting: true, manualLock: true))
        }
        XCTAssertFalse(clock.isLocked(at: inside, peerTesting: false, manualLock: false))
        XCTAssertTrue(clock.isLocked(at: outside, peerTesting: false, manualLock: false))
    }
}
