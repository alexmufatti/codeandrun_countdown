// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CountdownMenuBar",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "CountdownMenuBar",
            path: "Sources/CountdownMenuBar"
        )
    ]
)
