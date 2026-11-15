// swift-tools-version: 5.8
import PackageDescription
let package = Package(name: "Core", products: [.library(name: "BreakClock", targets: ["BreakClock"])],
                      targets: [.target(name: "BreakClock"), .testTarget(name: "BreakClockTests", dependencies: ["BreakClock"])])
