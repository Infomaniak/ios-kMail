// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Dependencies",
    dependencies: [
        .package(url: "https://github.com/apple/swift-algorithms", .upToNextMajor(from: "1.2.0")),
        .package(url: "https://github.com/Infomaniak/ios-login", .upToNextMajor(from: "6.0.0")),
        .package(url: "https://github.com/Infomaniak/ios-dependency-injection", .upToNextMajor(from: "2.0.0")),
        .package(url: "https://github.com/Infomaniak/swift-concurrency", .upToNextMajor(from: "0.0.5")),
        .package(url: "https://github.com/Infomaniak/ios-core", .revision("f55044d2156f39a5a2251e37bfe23f596227056e")),
        .package(url: "https://github.com/Infomaniak/ios-core-ui", .upToNextMajor(from: "7.1.0")),
        .package(url: "https://github.com/Infomaniak/ios-notifications", .upToNextMajor(from: "5.0.0")),
        .package(url: "https://github.com/Infomaniak/ios-create-account", .upToNextMajor(from: "6.0.0")),
        .package(url: "https://github.com/Infomaniak/ios-bug-tracker", .upToNextMajor(from: "4.0.0")),
        .package(url: "https://github.com/Infomaniak/ios-version-checker", .upToNextMajor(from: "4.0.0")),
        .package(url: "https://github.com/Infomaniak/swift-modal-presentation", .upToNextMajor(from: "1.0.0")),
        .package(url: "https://github.com/Infomaniak/SQRichTextEditor", .upToNextMajor(from: "1.1.1")),
        .package(url: "https://github.com/Infomaniak/SwiftSoup", .upToNextMajor(from: "1.1.0")),
        .package(url: "https://github.com/ProxymanApp/atlantis", .upToNextMajor(from: "1.21.0")),
        .package(url: "https://github.com/Alamofire/Alamofire", .upToNextMajor(from: "5.2.2")),
        .package(url: "https://github.com/CocoaLumberjack/CocoaLumberjack", .upToNextMajor(from: "3.7.0")),
        .package(url: "https://github.com/realm/realm-swift", .upToNextMajor(from: "10.41.0")),
        .package(url: "https://github.com/flowbe/SwiftRegex", .upToNextMajor(from: "1.0.0")),
        .package(url: "https://github.com/matomo-org/matomo-sdk-ios", .upToNextMajor(from: "7.5.1")),
        .package(url: "https://github.com/siteline/SwiftUI-Introspect", .upToNextMajor(from: "1.0.0")),
        .package(url: "https://github.com/markiv/SwiftUI-Shimmer", .upToNextMajor(from: "1.0.1")),
        .package(url: "https://github.com/dkk/WrappingHStack", .upToNextMajor(from: "2.0.0")),
        .package(url: "https://github.com/kean/Nuke", .upToNextMajor(from: "12.1.3")),
        .package(url: "https://github.com/airbnb/lottie-ios", .exact("3.5.0")),
        .package(url: "https://github.com/johnpatrickmorgan/NavigationBackport", .upToNextMajor(from: "0.8.1")),
        .package(url: "https://github.com/aheze/Popovers", .upToNextMajor(from: "1.3.2")),
        .package(url: "https://github.com/shaps80/SwiftUIBackports", .upToNextMajor(from: "1.15.1")),
        .package(url: "https://github.com/httpswift/swifter", .upToNextMajor(from: "1.5.0"))
    ]
)
