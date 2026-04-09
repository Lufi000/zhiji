// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "MiniMaxChatKit",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "MiniMaxChatKit", targets: ["MiniMaxChatKit"]),
    ],
    targets: [
        .target(name: "MiniMaxChatKit"),
    ]
)
