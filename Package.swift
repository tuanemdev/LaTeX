// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package: Package = Package(
    name: "LaTeX",
    products: [
        .library(
            name: "LaTeX",
            targets: ["LaTeX"]
        ),
    ],
    targets: [
        .target(
            name: "LaTeX",
            resources: [.process("Resources")],
        ),
    ]
)
