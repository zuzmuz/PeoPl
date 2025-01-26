// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ppllvm",
    dependencies: [
        .package(path: "../ppl.treesitter"),
        .package(url: "https://github.com/ChimeHQ/SwiftTreeSitter", from: "0.9.0"),
        .package(url: "https://github.com/llvm-swift/LLVMSwift", from: "0.8.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "Peopllvm",
            dependencies: [
                "SwiftTreeSitter",
                .product(name: "TreeSitterPeopl", package: "ppl.treesitter"),
            ]),
    ]
)
