// swift-tools-version:5.9
// omacos-shell — the native Panel (issue #10). Built with the Command Line Tools only:
//   swift build -c release   (see build.sh for the .app bundle)
import PackageDescription

let package = Package(
    name: "omacos-shell",
    platforms: [.macOS(.v14)],
    targets: [
        .target(name: "OmacosCore", path: "Sources/OmacosCore"),
        .executableTarget(name: "omacos-shell", dependencies: ["OmacosCore"], path: "Sources/omacos-shell"),
        .testTarget(name: "OmacosCoreTests", dependencies: ["OmacosCore"], path: "Tests/OmacosCoreTests"),
    ]
)
