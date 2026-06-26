// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "stayup",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "stayup", targets: ["stayup"])
    ],
    dependencies: [
        .package(url: "https://github.com/soffes/HotKey", from: "0.2.0")
    ],
    targets: [
        .executableTarget(
            name: "stayup",
            dependencies: ["HotKey"],
            path: "stayup"
        )
    ]
)
