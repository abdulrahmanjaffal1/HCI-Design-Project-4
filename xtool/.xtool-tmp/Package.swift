// swift-tools-version: 6.0
import PackageDescription
let package = Package(
    name: "Social-Builder",
    platforms: [
        .iOS("16.0"),
    ],
    dependencies: [
        .package(name: "RootPackage", path: "../.."),
    ],
    targets: [
        .executableTarget(
    name: "Social-App",
    dependencies: [
        .product(name: "Social", package: "RootPackage"),
    ],
    linkerSettings: [
    .unsafeFlags([
        "-Xlinker", "-rpath", "-Xlinker", "@executable_path/Frameworks",
    ]),
]
)
    ]
)
