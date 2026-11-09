// swift-tools-version:6.2

import PackageDescription

let package = Package(
    name: "ILFoundation",
    platforms: [.macOS(.v14), .iOS(.v17), .tvOS(.v17), .watchOS(.v10), .visionOS(.v26)],
    products: [
        .library(name: "ILFoundation", type: .dynamic, targets: ["ILFoundation"])
    ],
    targets: [
        .target(name: "ILFoundation"),
        .testTarget(name: "ILFoundationTests", dependencies: ["ILFoundation"])
    ]
)
