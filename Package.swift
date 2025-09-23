// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SDKFaceComponent",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        // Lo que importará el cliente:  import FaceCapture
        .library(name: "FaceCapture", targets: ["FaceCapture"])
    ],
    dependencies: [
        // Lottie 4.x
        .package(url: "https://github.com/airbnb/lottie-ios.git", from: "4.0.0"),
        .package(url: "https://github.com/bustoutsolutions/siesta.git", from: "1.5.2"),
    ],
    targets: [
        // ===== Opción A: binario LOCAL committeado en el repo =====
        //.binaryTarget(
        //    name: "SDKFaceComponent",
        //    path: "Artifacts/SDKFaceComponent.xcframework"
        //),
        // ===== Opción B: binario REMOTO (usa esta si publicas el zip en S3) =====
         .binaryTarget(
            name: "SDKFaceComponent",
            url: "https://nubarium-sdk-ios.s3.ca-central-1.amazonaws.com/releases/ios/SDKFaceComponent/b45a3e07-78d3-40e4-881c-7d45032e50db/v1.0.7/SDKFaceComponent.xcframework.zip",
            checksum: "cc77961b3de9087925fd2de97317c81a0eba9a7e0e6c226a9b65170a0960f2f4"
        ),

        // Wrapper que expone el API al cliente e integra Lottie
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
