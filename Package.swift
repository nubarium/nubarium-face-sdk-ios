// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SDKFaceComponent",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(name: "FaceCapture", targets: ["FaceCapture"])
    ],
    dependencies: [
        .package(url: "https://github.com/airbnb/lottie-ios.git", from: "4.0.0"),
        .package(url: "https://github.com/bustoutsolutions/siesta.git", from: "1.5.2"),
    ],
    targets: [
         .binaryTarget(
            name: "SDKFaceComponent",
            url: "ttps://nubarium-sdk-ios.s3.ca-central-1.amazonaws.com/releases/ios/SDKFaceComponent/2b9fa6e8-86db-4efb-a18f-1130a58749fe/v1.0.10/SDKFaceComponent.xcframework.zip",
            checksum: "dbc5598d36909202e0a735f1ffccb2c2d61ac18fed6cc805f98151d30f0af661"
        ),
        .target(
            name: "FaceCapture",
            dependencies: [
                .target(name: "SDKFaceComponent"),
                .product(name: "Lottie", package: "lottie-ios"),
                .product(name: "Siesta", package: "siesta"),
            ],
            path: "Sources/SDKFaceKit"
        )
    ]
)
