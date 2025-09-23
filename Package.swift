// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "NubariumSDkFace",
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
            url: "https://nubarium-sdk-ios.s3.ca-central-1.amazonaws.com/releases/ios/SDKFaceComponent/6568ada9-58f7-4a1e-9616-ba8b7d85488d/v1.0.12/SDKFaceComponent.xcframework.zip",
            checksum: "042b5dbe6064157aeab92e3e2d2c2701754ccfe14f3b08edd76236b77417ebdb"
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
