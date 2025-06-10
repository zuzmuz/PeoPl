// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "peoplcore",
    platforms: [
        .macOS(.v13)
    ],

    dependencies: [
        .package(path: "../ppl.treesitter"),
        .package(
            url: "https://github.com/ChimeHQ/SwiftTreeSitter", from: "0.9.0"),
        // .package(url: "https://github.com/llvm-swift/LLVMSwift", from: "0.8.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .systemLibrary(
            name: "cllvm",
            pkgConfig: "cllvm",
            providers: [
                .brew(["llvm"])
            ]),
        // .target(
        //     name: "PeoplLsp",
        //     dependencies: [
        //         "SwiftTreeSitter",
        //         .product(name: "TreeSitterPeoPl", package: "ppl.treesitter"),
        //     ]),
        .executableTarget(
            name: "PeoplCore",
            dependencies: [
                "SwiftTreeSitter",
                "cllvm",
                .product(name: "TreeSitterPeoPl", package: "ppl.treesitter"),
            ],
            // cxxSettings: [
            //     .headerSearchPath("/opt/homebrew/Cellar/llvm/19.1.7/include/include"),
            // ]
        ),
        .testTarget(
            name: "PeoplCoreTests",
            dependencies: ["PeoplCore"],
            resources: [
                .process("Resources")
            ]
        ),
    ],
    cxxLanguageStandard: .cxx17
)
