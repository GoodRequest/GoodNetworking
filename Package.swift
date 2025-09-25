// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "GoodNetworking",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "GoodNetworking",
            targets: ["GoodNetworking"]
        )
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
    ],
    targets: [
        .target(
            name: "GoodNetworking",
            dependencies: [],
            path: "./Sources/GoodNetworking",
            resources: [.copy("PrivacyInfo.xcprivacy")],
            swiftSettings: [
                .swiftLanguageMode(.v6),
//                .unsafeFlags(["-Onone"])
            ]
        ),
        .testTarget(
            name: "GoodNetworkingTests",
            dependencies: ["GoodNetworking"],
            resources: [],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
    ]
)
