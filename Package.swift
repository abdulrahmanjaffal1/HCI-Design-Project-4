// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SocialApp",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "SocialApp", targets: ["SocialApp"]),
    ],
    targets: [
        .target(
            name: "SocialApp",
            resources: [.process("Resources")]
        ),
    ],
    swiftLanguageModes: [.v5]
)
