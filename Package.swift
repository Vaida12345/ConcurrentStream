// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ConcurrentStream",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
        .watchOS(.v10),
        .tvOS(.v17),
        .visionOS(.v1)
    ], products: [
        .library(name: "ConcurrentStream", targets: ["ConcurrentStream"]),
    ], targets: [
        .target(name: "ConcurrentStream"),
        .executableTarget(name: "Client", dependencies: ["ConcurrentStream"]),
        .testTarget(name: "ConcurrentStreamTests", dependencies: ["ConcurrentStream"]),
    ], swiftLanguageModes: [.v5]
)
