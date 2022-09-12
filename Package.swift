// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DarkeyeCore",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .library(name: "DarkeyeCore", targets: ["DarkeyeCore"]),
    ],
    dependencies: [
        .package(url: "https://github.com/amraboelela/SwiftLevelDB", .branch("master")),
        .package(url: "https://github.com/maparoni/Fuzi.git", .branch("master")),
        .package(url: "https://github.com/amraboelela/SwiftEncrypt", .branch("main")),
        
    ],
    targets: [
        .target(
            name: "DarkeyeCore",
            dependencies: ["SwiftLevelDB", "Fuzi", "SwiftEncrypt"]),
        .testTarget(name: "DarkeyeCoreTests", dependencies: ["DarkeyeCore"]),
    ]
)
