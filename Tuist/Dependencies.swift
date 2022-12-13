import ProjectDescription

let dependencies = Dependencies(
    swiftPackageManager: [
        .remote(url: "https://github.com/pointfreeco/swift-composable-architecture", requirement: .upToNextMajor(from: "0.19.0")),
        .remote(url: "https://github.com/Bersaelor/SwiftSplines", requirement: .upToNextMajor(from: "0.3.0")),
    ],
    platforms: [.iOS]
)
