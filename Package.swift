// swift-tools-version:5.9

import PackageDescription

let package = Package(
    name: "BambuserCommerceSDK",
    platforms: [
        .iOS(.v14),
    ],
    products: [
        .library(
            name: "BambuserCommerceSDK",
            targets: ["BambuserCommerceSDK"]
        ),
    ],
    dependencies: [],
    targets: [
        .binaryTarget(
            name: "BambuserCommerceSDK",
            path: "Framework/BambuserCommerceSDK.xcframework"
        ),
    ]
)
