// swift-tools-version: 6.2

import PackageDescription

/// A function keeps the semantics of the module that declares it, so this has to be applied to
/// every target, tests included. Enabling it for some targets only would leave the package with
/// two rule sets and diagnostics that depend on which side of a module boundary a call sits.
let approachableConcurrency: [SwiftSetting] = [
    .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
    .enableUpcomingFeature("InferIsolatedConformances")
]

let package: Package = Package(
    name: "Core",
    platforms: [
        .macOS(.v15),
        .iOS(.v18),
        .watchOS(.v11)
    ],
    products: [
        .library(
            name: "Account",
            targets: [
                "Account"
            ]),
        .executable(
            name: "autoconfig",
            targets: [
                "AutoconfigurationCLI"
            ]),
        .library(
            name: "Autoconfiguration",
            targets: [
                "Autoconfiguration"
            ]),
        .library(
            name: "Core",
            targets: [
                "Core"
            ]),
        .library(
            name: "EmailAddress",
            targets: [
                "EmailAddress"
            ]),
        .library(
            name: "IMAP",
            targets: [
                "IMAP"
            ]),
        .library(
            name: "JMAP",
            targets: [
                "JMAP"
            ]),
        .library(
            name: "MIME",
            targets: [
                "MIME"
            ]),
        .library(
            name: "SMTP",
            targets: [
                "SMTP"
            ])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", branch: "main"),
        .package(url: "https://github.com/apple/swift-async-dns-resolver", branch: "main"),
        .package(url: "https://github.com/apple/swift-nio", branch: "main"),
        .package(url: "https://github.com/apple/swift-nio-extras", branch: "main"),
        .package(url: "https://github.com/apple/swift-nio-imap", branch: "main"),
        .package(url: "https://github.com/apple/swift-nio-ssl", branch: "main"),
        .package(url: "https://github.com/apple/swift-nio-transport-services", branch: "main"),
        .package(url: "https://github.com/groue/GRDB.swift.git", branch: "master")
    ],
    targets: [
        .target(
            name: "Account",
            dependencies: [
                "Autoconfiguration",
                "EmailAddress",
                "IMAP",
                "JMAP",
                "MIME",
                "SMTP",
                .product(name: "GRDB", package: "GRDB.swift")
            ],
            swiftSettings: approachableConcurrency),
        .testTarget(
            name: "AccountTests",
            dependencies: [
                "Account"
            ],
            resources: [
                .process("Resources")
            ],
            swiftSettings: approachableConcurrency),
        .target(
            name: "Autoconfiguration",
            dependencies: [
                .product(name: "AsyncDNSResolver", package: "swift-async-dns-resolver")
            ],
            swiftSettings: approachableConcurrency),
        .executableTarget(
            name: "AutoconfigurationCLI",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                "Autoconfiguration"
            ],
            swiftSettings: approachableConcurrency),
        .testTarget(
            name: "AutoconfigurationTests",
            dependencies: [
                "Autoconfiguration"
            ],
            swiftSettings: approachableConcurrency),
        .target(
            name: "Core",
            dependencies: [
                "Account"
            ],
            swiftSettings: approachableConcurrency),
        .target(
            name: "EmailAddress",
            swiftSettings: approachableConcurrency),
        .testTarget(
            name: "EmailAddressTests",
            dependencies: [
                "EmailAddress"
            ],
            swiftSettings: approachableConcurrency),
        .target(
            name: "IMAP",
            dependencies: [
                .product(name: "NIOIMAP", package: "swift-nio-imap"),
                .product(name: "NIOSSL", package: "swift-nio-ssl"),
                "EmailAddress",
                "MIME"
            ],
            swiftSettings: approachableConcurrency),
        .testTarget(
            name: "IMAPTests",
            dependencies: [
                "IMAP"
            ],
            swiftSettings: approachableConcurrency),
        .target(
            name: "JMAP",
            dependencies: [
                "EmailAddress",
                "MIME"
            ],
            swiftSettings: approachableConcurrency),
        .testTarget(
            name: "JMAPTests",
            dependencies: [
                "JMAP"
            ],
            swiftSettings: approachableConcurrency),
        .target(
            name: "MIME",
            swiftSettings: approachableConcurrency),
        .testTarget(
            name: "MIMETests",
            dependencies: [
                "MIME"
            ],
            resources: [
                .process("Resources")
            ],
            swiftSettings: approachableConcurrency),
        .target(
            name: "SMTP",
            dependencies: [
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "NIOExtras", package: "swift-nio-extras"),
                .product(name: "NIOSSL", package: "swift-nio-ssl"),
                .product(name: "NIOTransportServices", package: "swift-nio-transport-services"),
                "EmailAddress",
                "MIME"
            ],
            swiftSettings: approachableConcurrency),
        .testTarget(
            name: "SMTPTests",
            dependencies: [
                "SMTP"
            ],
            swiftSettings: approachableConcurrency)
    ])
