// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ConcurrentStream",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .watchOS(.v6),
        .tvOS(.v13)
    ], products: [
        .library(name: "ConcurrentStream", targets: ["ConcurrentStream"]),
    ], targets: [
        .target(name: "ConcurrentStream", swiftSettings: [.enableUpcomingFeature("FullTypedThrows"), .enableExperimentalFeature("NoncopyableGenerics")]),
        .executableTarget(name: "Client", dependencies: ["ConcurrentStream"]),
        .testTarget(name: "ConcurrentStreamTests", dependencies: ["ConcurrentStream"]),
    ]
)
