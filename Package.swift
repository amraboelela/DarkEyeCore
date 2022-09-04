// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DarkEyeCore",
    platforms: [
        .macOS(.v11)
    ],
    products: [
        .library(name: "DarkEyeCore", targets: ["DarkEyeCore"]),
    ],
    dependencies: [
        .package(url: "https://github.com/amraboelela/SwiftLevelDB", .branch("master")),
        .package(url: "https://github.com/maparoni/Fuzi.git", .branch("master")),
        .package(url: "https://github.com/amraboelela/SwiftEncrypt", .branch("main")),
        
    ],
    targets: [
        .target(
            name: "DarkEyeCore",
            dependencies: ["SwiftLevelDB", "Fuzi", "SwiftEncrypt"]),
        .testTarget(name: "DarkEyeCoreTests", dependencies: ["DarkEyeCore"]),
    ]
)
