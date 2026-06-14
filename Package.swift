// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Metallic",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .macCatalyst(.v17),
        .tvOS(.v17),
        .watchOS(.v10),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "Metallic",
            targets: ["Metallic"]
        ),
    ],
    targets: [
        .target(
            name: "Metallic",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
