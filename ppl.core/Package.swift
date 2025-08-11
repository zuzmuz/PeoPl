// swift-tools-version: 6.1
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
            url: "https://github.com/ChimeHQ/SwiftTreeSitter",
            from: "0.9.0"),
        .package(
            url: "https://github.com/apple/swift-argument-parser.git",
            from: "1.0.0"),
        // TODO
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
            ]
        ),
        // .target(
        //     name: "Core",
        //     dependencies: [
        //         "SwiftTreeSitter",
        //         "cllvm",
        //         .product(name: "TreeSitterPeoPl", package: "ppl.treesitter"),
        //     ],
        // ),
        .target(
            name: "Utils"
        ),
        .target(
            name: "Lsp",
            dependencies: ["Utils"]
        ),
        .executableTarget(
            name: "Main",
            // dependencies: [
            //     "Core", "Lsp",
            // ]
            dependencies: [
                "SwiftTreeSitter",
                "cllvm",
                "Lsp",
                .product(
                    name: "ArgumentParser", package: "swift-argument-parser"),
                .product(
                    name: "TreeSitterPeoPl", package: "ppl.treesitter"),
            ],
        ),
        .testTarget(
            name: "MainTests",
            dependencies: ["Main"],
            resources: [
                .process("Resources")
            ]
        ),
    ],
    cxxLanguageStandard: .cxx17
)
