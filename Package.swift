// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "JunkDrawer",
    platforms: [
        .iOS(.v16),
        .macOS(.v10_13),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "JunkDrawer",
            targets: ["JunkDrawer"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/yamoridon/ColorThiefSwift", from: "0.5.0"),
        .package(url: "https://github.com/keublitz/Dialogue", from: "0.9.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "JunkDrawer",
            dependencies: [
                .product(name: "ColorThiefSwift", package: "ColorThiefSwift"),
                .product(name: "Dialogue", package: "Dialogue")
            ]
        ),
    ]
)
