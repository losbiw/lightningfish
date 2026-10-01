// swift-tools-version: 6.2

import PackageDescription

let approachableConcurrency: [SwiftSetting] = [
    .defaultIsolation(MainActor.self),
    .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
    .enableUpcomingFeature("InferIsolatedConformances")
]

let package: Package = Package(
    name: "Bolt",
    platforms: [
        .macOS(.v15),
        .iOS(.v18),
        .watchOS(.v11)
    ],
    products: [
        .library(
            name: "Bolt",
            targets: [
                "Bolt"
            ]),
        .library(
            name: "BoltUI",
            targets: [
                "BoltUI"
            ])
    ],
    dependencies: [
        .package(url: "https://github.com/toddheasley/bolt-design-system", branch: "swift-package")
    ],
    targets: [
        .target(
            name: "Bolt",
            dependencies: [
                "BoltUI"
            ],
            swiftSettings: approachableConcurrency),
        .target(
            name: "BoltUI",
            dependencies: [
                .product(name: "BoltDesignSystem", package: "bolt-design-system")
            ],
            swiftSettings: approachableConcurrency),
        .testTarget(
            name: "BoltUITests",
            dependencies: [
                "BoltUI"
            ],
            swiftSettings: approachableConcurrency)
    ])
