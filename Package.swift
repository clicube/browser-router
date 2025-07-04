// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SwiftBrowserRouter",
    platforms: [
        .macOS(.v12)
    ],
    dependencies: [
        // Add library for handling TOML files
        .package(url: "https://github.com/LebJe/TOMLKit.git", from: "0.5.6"),
    ],
    targets: [
        .executableTarget(
            name: "SwiftBrowserRouter",
            dependencies: [
                // Link library to target
                .product(name: "TOMLKit", package: "TOMLKit"),
            ]
        ),
    ]
)
