// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Simpllvm",
    dependencies: [
        .package(path: "../simpl.treesitter"),
        .package(url: "https://github.com/ChimeHQ/SwiftTreeSitter", branch: "main"),
        .package(url: "https://github.com/llvm-swift/LLVMSwift", from: "0.8.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "Simpllvm",
            dependencies: [
                "SwiftTreeSitter",
                .product(name: "SwiftTreeSitterLayer", package: "SwiftTreeSitter"),
                .product(name: "TreeSitterSimpl", package: "simpl.treesitter"),
            ]),
    ]
)