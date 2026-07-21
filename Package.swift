// swift-tools-version: 6.3

import PackageDescription

let package = Package(
    name: "xt-swift-cpu8088",
    products: [
        .library(
            name: "xt-swift-cpu8088",
            targets: ["XTSwiftCPU8088"]
        ),
    ],
    targets: [
        .target(
            name: "XTSwiftCPU8088"
        ),
        .testTarget(
            name: "XTSwiftCPU8088Tests",
            dependencies: ["XTSwiftCPU8088"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
