// swift-tools-version: 5.9
// This is a Skip (https://skip.tools) package,
// containing a Swift Package Manager project
// that will use the Skip build plugin to transpile the
// Swift Package, Sources, and Tests into an
// Android Gradle Project with Kotlin sources and JUnit tests.
import PackageDescription

let package = Package(
    name: "skip-amplify",
    defaultLocalization: "en",
    platforms: [.iOS(.v16), .macOS(.v13), .tvOS(.v16), .watchOS(.v9), .macCatalyst(.v16)],
    products: [
        .library(name: "SkipAmplify", type: .dynamic, targets: ["SkipAmplify"]),
    ],
    dependencies: [
        .package(url: "https://source.skip.tools/skip.git", from: "1.2.26"),
        .package(url: "https://source.skip.tools/skip-foundation.git", from: "1.0.0"),
        .package(url: "https://github.com/aws-amplify/amplify-swift.git", from: "2.45.4")
    ],
    targets: [
        .target(name: "SkipAmplify", dependencies: [
            .product(name: "SkipFoundation", package: "skip-foundation"),
            .product(name: "Amplify", package: "amplify-swift")
        ], resources: [.process("Resources")], plugins: [.plugin(name: "skipstone", package: "skip")]),
        .testTarget(name: "SkipAmplifyTests", dependencies: [
            "SkipAmplify",
            .product(name: "SkipTest", package: "skip")
        ], resources: [.process("Resources")], plugins: [.plugin(name: "skipstone", package: "skip")]),
    ]
)
