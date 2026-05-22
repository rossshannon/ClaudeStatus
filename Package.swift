// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "ClaudeStatus",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "ClaudeStatusCore",
            targets: ["ClaudeStatusCore"]
        ),
        .executable(
            name: "ClaudeStatus",
            targets: ["ClaudeStatusApp"]
        )
    ],
    targets: [
        .target(
            name: "ClaudeStatusCore"
        ),
        .executableTarget(
            name: "ClaudeStatusApp",
            dependencies: ["ClaudeStatusCore"]
        ),
        .testTarget(
            name: "ClaudeStatusCoreTests",
            dependencies: ["ClaudeStatusCore"]
        )
    ]
)
