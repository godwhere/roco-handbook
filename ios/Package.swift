// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "RocoHandbook",
    platforms: [.iOS(.v15), .macOS(.v12)],
    products: [.library(name: "HandbookCore", targets: ["HandbookCore"])],
    targets: [
        .systemLibrary(name: "CSystem"),
        .target(name: "HandbookCore", dependencies: ["CSystem"]),
        .testTarget(name: "HandbookCoreTests", dependencies: ["HandbookCore"]),
    ]
)
