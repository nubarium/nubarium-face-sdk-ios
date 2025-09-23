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
            url: "https://nubarium-sdk-ios.s3.ca-central-1.amazonaws.com/releases/ios/SDKFaceComponent/f06f02c9-53b2-4d07-9cf1-8356369fb48f/v1.0.13/SDKFaceComponent.xcframework.zip",
            checksum: "69c07a4772228386f49882e4cac520bec5b44ec72bd97d30bf811c682f526292"
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
