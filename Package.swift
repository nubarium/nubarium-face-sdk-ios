// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SDKFaceComponent",
    platforms: [.iOS(.v13)],
    products: [
        .library(name: "SDKFaceComponent", targets: ["SDKFaceKit"])
    ],
    dependencies: [
        .package(url: "https://github.com/airbnb/lottie-ios.git", from: "4.0.0")
    ],
    targets: [
        .binaryTarget(
            name: "SDKFaceComponent",
            url: "https://nubarium-sdk-ios.s3.ca-central-1.amazonaws.com/releases/ios/SDKFaceComponent/v1.0.5/SDKFaceComponent.xcframework.zip",
            checksum: "685b3ac2dd5826d3f68941180e1a7b3641c98d045da18341d91ac2529fc51605"
        ),
        .target(
            name: "SDKFaceKit",
            dependencies: [
                .target(name: "SDKFaceComponent"),
                .product(name: "Lottie", package: "lottie-ios")
            ],
            path: "Sources/SDKFaceKit"
        )
    ]
)
