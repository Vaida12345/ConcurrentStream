// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ConcurrentStream",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
        .watchOS(.v9),
        .tvOS(.v16)
    ], products: [
        .library(name: "ConcurrentStream", targets: ["ConcurrentStream"]),
    ], targets: [
        .target(name: "ConcurrentStream"),
        .executableTarget(name: "Client", dependencies: ["ConcurrentStream"]),
        .testTarget(name: "ConcurrentStreamTests", dependencies: ["ConcurrentStream"]),
    ]
)
