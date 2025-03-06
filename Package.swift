// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "PoilabsPositioning",
    platforms: [
        .iOS(.v12)
    ],
    products: [
        .library(
            name: "PoilabsPositioning",
            targets: ["PoilabsPositioning"])
    ],
    targets: [
        .binaryTarget(
            name: "PoilabsPositioning",
            path: "PoilabsPositioning.xcframework"
        )
    ]
) 