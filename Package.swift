// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DarkEyeCore",
    products: [
        .library(name: "DarkEyeCore", targets: ["DarkEyeCore"]),
    ],
    dependencies: [
        .package(url: "https://github.com/amraboelela/SwiftLevelDB", .branch("master")),
        .package(url: "https://github.com/maparoni/Fuzi.git", .branch("master")),
        .package(url: "https://github.com/amraboelela/CommonCrypto", .branch("master")),
        
    ],
    targets: [
        /*.target(name: "DarkEyeCore", dependencies: [
            .product(name: "SwiftLevelDB", package: "SwiftLevelDB"),
            .product(name: "CommonCrypto", package: "CommonDigest"),
            .product(name: "Fuzi", package: "Fuzi")
        ]),
        */
        .target(
            name: "DarkEyeCore",
            dependencies: ["SwiftLevelDB", "Fuzi", "CommonCrypto"]),
        .testTarget(name: "DarkEyeCoreTests", dependencies: ["DarkEyeCore"]),
    ]
)
