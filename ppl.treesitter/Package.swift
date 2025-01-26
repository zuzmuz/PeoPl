// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "TreeSitterPeoPl",
    products: [
        .library(name: "TreeSitterPeoPl", targets: ["TreeSitterPeoPl"]),
    ],
    dependencies: [
        .package(url: "https://github.com/ChimeHQ/SwiftTreeSitter", from: "0.8.0"),
    ],
    targets: [
        .target(
            name: "TreeSitterPeoPl",
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
            name: "TreeSitterPeoPlTests",
            dependencies: [
                "SwiftTreeSitter",
                "TreeSitterPeoPl",
            ],
            path: "bindings/swift/TreeSitterPeoPlTests"
        )
    ],
    cLanguageStandard: .c11
)
