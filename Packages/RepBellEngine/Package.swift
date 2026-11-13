// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "RepBellEngine",
    products: [
        .library(name: "RepBellEngine", targets: ["RepBellEngine"])
    ],
    targets: [
        .target(name: "RepBellEngine"),
        .testTarget(name: "RepBellEngineTests", dependencies: ["RepBellEngine"])
    ],
    swiftLanguageModes: [.v6]
)
