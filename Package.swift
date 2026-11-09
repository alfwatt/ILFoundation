// swift-tools-version:5.10

import PackageDescription

let package = Package(
    name: "ILFoundation",
    platforms: [.macOS(.v10_14), .iOS(.v14), .tvOS(.v14), .visionOS("26.0")],
    products: [
        .library( name: "ILFoundation", type: .dynamic, targets: ["ILFoundation"]),
        .library( name: "ILFoundationSwift", type: . dynamic, targets: ["ILFoundationSwift"])
    ],
    targets: [
        .target(name: "ILFoundation"),
        .target(name: "ILFoundationSwift", dependencies: ["ILFoundation"])
    ]
)
