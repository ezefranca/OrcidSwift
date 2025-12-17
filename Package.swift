// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "OrcidSwift",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .tvOS(.v13),
        .watchOS(.v6),
    ],
    products: [
        .library(name: "OrcidSwift", targets: ["OrcidSwift"]),
    ],
    dependencies: [
        // remove swift-testing dependency (see section 2)
    ],
    targets: [
        .target(name: "OrcidSwift"),
        .testTarget(
            name: "OrcidSwiftTests",
            dependencies: ["OrcidSwift"],
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "OrcidSwiftIntegrationTests",
            dependencies: ["OrcidSwift"]
        ),
    ]
)

