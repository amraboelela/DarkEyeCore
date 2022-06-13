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
        //.package(url: "https://github.com/honghaoz/Ji.git", from: "5.0.0")
        //.package(url: "https://github.com/cezheng/Fuzi.git", from: "3.0.0")
        .package(url: "https://github.com/maparoni/Fuzi.git", .branch("master"))
        //https://github.com/maparoni/Fuzi
        //.package(url: "https://github.com/ndavon/NDHpple.git", from: "1.0.0")
        
    ],
    targets: [
        .target(name: "DarkEyeCore", dependencies: [
            .product(name: "SwiftLevelDB", package: "SwiftLevelDB"),
            .product(name: "Fuzi", package: "Fuzi")
        ]),
        .testTarget(name: "DarkEyeCoreTests", dependencies: ["DarkEyeCore"]),
    ]
)
