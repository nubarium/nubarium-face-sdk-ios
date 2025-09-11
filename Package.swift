// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SDKFaceComponent",
    defaultLocalization: "en",        // 👈 AÑADE ESTO (o "es" si usas es.lproj)
    platforms: [.iOS(.v13)],
    products: [
        .library(name: "SDKFaceComponent", targets: ["SDKFaceComponent"])
    ],
    dependencies: [
        .package(url: "https://github.com/airbnb/lottie-ios.git", from: "4.0.0"),
        .package(url: "https://github.com/bustoutsolutions/siesta.git", from: "1.5.0"),
        .package(url: "https://github.com/Ekhoo/Device.git", from: "3.7.0")
    ],
    targets: [
        .target(
            name: "SDKFaceComponent",
            dependencies: [
                .product(name: "Lottie", package: "lottie-ios"),
                .product(name: "Siesta", package: "siesta"),
                .product(name: "Device", package: "device")
            ],
            path: "Sources/SDKFaceComponent",
            resources: [
                .process("Resources") // 👈 necesario para que exista Bundle.module
            ],
            linkerSettings: [
                .linkedFramework("AVFoundation"),
                .linkedFramework("Vision"),
                .linkedFramework("CoreMedia"),
                .linkedFramework("QuartzCore"),
                .linkedFramework("UIKit")
            ]
        ),
        .testTarget(
            name: "SDKFaceComponentTests",
            dependencies: ["SDKFaceComponent"]
        )
    ]
)
