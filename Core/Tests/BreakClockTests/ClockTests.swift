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
    func testDemoRelaunch() {
        let origin = Date()
        let clock = BreakClock(zone: .current, demoStart: origin)
        XCTAssertNil(clock.active(at: origin.addingTimeInterval(19)))
        XCTAssertNotNil(clock.active(at: origin.addingTimeInterval(20)))
        XCTAssertNotNil(clock.active(at: origin.addingTimeInterval(79)))
        XCTAssertNil(clock.active(at: origin.addingTimeInterval(80)))
    }
}
