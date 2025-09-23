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
            url: "https://nubarium-sdk-ios.s3.ca-central-1.amazonaws.com/releases/ios/SDKFaceComponent/067f4b69-74e7-4230-b57c-e34162aee58b/v1.0.11/SDKFaceComponent.xcframework.zip",
            checksum: "020bc950e75daaba3be41b3a992eb01f1ba82e279c6f4e45b096ea7841c08019"
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
