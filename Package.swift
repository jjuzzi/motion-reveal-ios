// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "MotionRevealDependencies",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "DependencySmokeTest",
            targets: ["DependencySmokeTest"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/rive-app/rive-ios", from: "6.13.0"),
        .package(url: "https://github.com/airbnb/lottie-spm.git", from: "4.6.0")
    ],
    targets: [
        .target(
            name: "DependencySmokeTest",
            dependencies: [
                .product(name: "RiveRuntime", package: "rive-ios"),
                .product(name: "Lottie", package: "lottie-spm")
            ]
        )
    ]
)
