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
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "GoodNetworking",
            targets: ["GoodNetworking"]
        )
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/KittyMac/Sextant.git", .upToNextMinor(from: "0.4.31"))
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "GoodNetworking",
            dependencies: [
                .product(name: "Sextant", package: "Sextant")
            ],
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
