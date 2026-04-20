// swift-tools-version: 6.3

import PackageDescription

let package = Package(
    name: "OCRMenuBarApp",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "OCRMenuBarApp", targets: ["OCRMenuBarApp"])
    ],
    targets: [
        .executableTarget(
            name: "OCRMenuBarApp"
        )
    ],
    swiftLanguageModes: [.v6]
)
