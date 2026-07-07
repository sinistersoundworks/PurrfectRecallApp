// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PurrfectRecallKit",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(name: "PurrfectRecallKit", targets: ["PurrfectRecallKit"]),
    ],
    targets: [
        .target(name: "PurrfectRecallKit"),
    ]
)
