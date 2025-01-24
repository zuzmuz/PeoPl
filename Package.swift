// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "TreeSitterSimpl",
    products: [
        .library(name: "TreeSitterSimpl", targets: ["TreeSitterSimpl"]),
    ],
    dependencies: [
        .package(url: "https://github.com/ChimeHQ/SwiftTreeSitter", from: "0.8.0"),
    ],
    targets: [
        .target(
            name: "TreeSitterSimpl",
            dependencies: [],
            path: ".",
            sources: [
                "src/parser.c",
                // NOTE: if your language has an external scanner, add it here.
            ],
            resources: [
                .copy("queries")
            ],
            publicHeadersPath: "bindings/swift",
            cSettings: [.headerSearchPath("src")]
        ),
        .testTarget(
            name: "TreeSitterSimplTests",
            dependencies: [
                "SwiftTreeSitter",
                "TreeSitterSimpl",
            ],
            path: "bindings/swift/TreeSitterSimplTests"
        )
    ],
    cLanguageStandard: .c11
)
