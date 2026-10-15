// swift-tools-version:5.9
// omacos-shell — the native Panel (issue #10) and Notes (ADR 0004). Built with the Command Line
// Tools only:
//   swift build -c release   (see build.sh for the .app bundles)
import PackageDescription

let package = Package(
    name: "omacos-shell",
    platforms: [.macOS(.v14)],
    targets: [
        .target(name: "OmacosCore", path: "Sources/OmacosCore"),
        // vendored from github.com/msjurset/swift-vim-engine (MIT), see Sources/VimEngine/LICENSE
        .target(name: "VimEngine", path: "Sources/VimEngine", exclude: ["LICENSE"]),
        .executableTarget(name: "omacos-shell", dependencies: ["OmacosCore"], path: "Sources/omacos-shell"),
        .executableTarget(name: "omacos-notes", dependencies: ["OmacosCore", "VimEngine"], path: "Sources/omacos-notes"),
        .testTarget(name: "OmacosCoreTests", dependencies: ["OmacosCore"], path: "Tests/OmacosCoreTests"),
        // the engine's own harness (no XCTest in the Command Line Tools): swift run VimEngineTests
        .executableTarget(name: "VimEngineTests", dependencies: ["VimEngine"], path: "Tests/VimEngineTests"),
    ]
)
