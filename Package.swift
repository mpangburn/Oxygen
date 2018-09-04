// swift-tools-version:4.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Oxygen",
    products: [
        .library(
            name: "Oxygen",
            targets: ["Oxygen"]),
    ],
    dependencies: [

    ],
    targets: [
        .target(
            name: "Oxygen",
            dependencies: [])
    ]
)
