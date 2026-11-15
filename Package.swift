// swift-tools-version: 5.8
import PackageDescription

let package = Package(
    name: "Social",
    platforms: [.iOS(.v16)],
    products: [.library(name: "Social", targets: ["Social"])],
    dependencies: [.package(path: "Core")],
    targets: [.target(name: "Social", dependencies: [.product(name: "BreakClock", package: "Core")],
                      resources: [.copy("Photos")])]
)
