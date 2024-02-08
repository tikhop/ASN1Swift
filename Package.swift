// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let visionOSSetting: SwiftSetting = .define("VISION_OS", .when(platforms: [.visionOS]))

let package = Package(
    name: "ASN1Swift",
	platforms: [.macOS(.v10_13),
				.iOS(.v12),
				.tvOS(.v12),
                .watchOS(.v6),
                .visionOS(.v1)],
    products: [
        .library(
            name: "ASN1Swift",
            targets: ["ASN1Swift"]),
    ],
    targets: [
        .target(
            name: "ASN1Swift",
            dependencies: []),
        .testTarget(
            name: "ASN1SwiftTests",
            dependencies: ["ASN1Swift"]),
    ]
)
