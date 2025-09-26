// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "NubariumSDKFace",
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
            url: "https://nubarium-sdk-ios.s3.ca-central-1.amazonaws.com/releases/ios/SDKFaceComponent/b6fba6b4-f844-4f3c-af0b-f1689d36723c/v1.0.14/SDKFaceComponent.xcframework.zip",
            checksum: "7475c9c43aec00cb97dd432845036159f6f7896cc7c3444c482c618c1fd9c2cf"
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
