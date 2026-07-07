// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "StudyWebKit",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(name: "StudyWebKit", targets: ["StudyWebKit"]),
    ],
    targets: [
        .target(name: "StudyWebKit"),
    ]
)
