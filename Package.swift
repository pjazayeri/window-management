// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "WindowManager",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "WindowManager",
            path: "Sources/WindowManager",
            resources: [.process("Assets.xcassets")]
        )
    ]
)
