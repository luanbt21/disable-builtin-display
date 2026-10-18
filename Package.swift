// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "builtin-display",
    platforms: [.macOS(.v12)],
    targets: [
        .executableTarget(name: "builtin-display", path: "Sources/builtin-display")
    ]
)
