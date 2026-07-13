// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SoFlow",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "SOFLOWCore", targets: ["SOFLOWCore"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "SOFLOWCore",
            path: "Sources/SOFLOWCore"
        ),
        .testTarget(
            name: "SOFLOWCoreTests",
            dependencies: ["SOFLOWCore"],
            path: "Tests/SOFLOWCoreTests"
        ),
    ]
)
