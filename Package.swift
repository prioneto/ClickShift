// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "ClickShift",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "ClickShiftCore", targets: ["ClickShiftCore"]),
        .executable(name: "ClickShift", targets: ["ClickShiftApp"]),
    ],
    targets: [
        .target(name: "ClickShiftCore"),
        .executableTarget(
            name: "ClickShiftApp",
            dependencies: ["ClickShiftCore"]
        ),
        .testTarget(
            name: "ClickShiftCoreTests",
            dependencies: ["ClickShiftCore"]
        ),
    ]
)
