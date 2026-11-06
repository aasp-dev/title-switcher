// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "TitleSwitcher",
    platforms: [.macOS(.v14)],
    targets: [
        .target(name: "SwitcherCore"),
        .executableTarget(name: "TitleSwitcher", dependencies: ["SwitcherCore"]),
        .testTarget(name: "SwitcherCoreTests", dependencies: ["SwitcherCore"]),
    ]
)
