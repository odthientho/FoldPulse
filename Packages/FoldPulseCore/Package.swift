// swift-tools-version: 6.0
// FoldPulseCore — pure-Swift domain logic for FoldPulse (no UIKit/SwiftUI/SwiftData).
// Builds and tests on Linux and on Apple platforms.
import PackageDescription

let package = Package(
    name: "FoldPulseCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "FoldPulseCore", targets: ["FoldPulseCore"]),
    ],
    targets: [
        .target(name: "FoldPulseCore"),
        .testTarget(name: "FoldPulseCoreTests", dependencies: ["FoldPulseCore"]),
    ]
)
