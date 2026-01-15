// swift-tools-version: 5.9
import PackageDescription

#if TUIST
import ProjectDescription
import ProjectDescriptionHelpers

let packageSettings = PackageSettings(
    productTypes: [
        "Alamofire": .framework,
        "Algorithms": .staticFramework,
        "Atlantis": .staticFramework,
        "DesignSystem": .framework,
        "DeviceAssociation": .framework,
        "ElegantEmojiPicker": .framework,
        "InAppTwoFactorAuthentication": .framework,
        "InfomaniakBugTracker": .framework,
        "InfomaniakConcurrency": .framework,
        "InfomaniakCoreCommonUI": .framework,
        "InfomaniakCoreDB": .framework,
        "InfomaniakCoreSwiftUI": .framework,
        "InfomaniakCoreUIKit": .framework,
        "InfomaniakCoreUIResources": .framework,
        "InfomaniakCore": .framework,
        "InfomaniakCreateAccount": .framework,
        "InfomaniakDeviceCheck": .staticFramework,
        "InfomaniakDI": .framework,
        "InfomaniakLogin": .framework,
        "InfomaniakNotifications": .framework,
        "InfomaniakOnboarding": .framework,
        "InfomaniakRichHTMLEditor": .framework,
        "InterAppLogin": .framework,
        "InternalCollectionsUtilities": .framework,
        "KSuiteUtils": .framework,
        "KSuite": .framework,
        "MyKSuite": .framework,
        "NavigationBackport": .framework,
        "NukeUI": .framework,
        "Nuke": .framework,
        "OrderedCollections": .framework,
        "Popovers": .framework,
        "RealmSwift": .framework,
        "Realm": .framework,
        "Sentry-Dynamic": .framework,
        "Shimmer": .staticFramework,
        "SnackBar": .framework,
        "SVGKit": .framework,
        "Swifter": .staticFramework,
        "SwiftModalPresentation": .framework,
        "SwiftRegex": .framework,
        "SwiftSoup": .framework,
        "SwiftUIBackports": .framework,
        "SwiftUIIntrospect": .framework,
        "VersionChecker": .framework,
        "WrappingHStack": .framework,
        "_LottieStub": .framework
    ]
)

#endif

let package = Package(
    name: "Dependencies",
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire", .upToNextMajor(from: "5.2.2")),
        .package(url: "https://github.com/apple/swift-algorithms", .upToNextMajor(from: "1.2.0")),
        .package(url: "https://github.com/apple/swift-collections", .upToNextMajor(from: "1.1.4")),
        .package(url: "https://github.com/dkk/WrappingHStack", .upToNextMajor(from: "2.0.0")),
        .package(url: "https://github.com/flowbe/SwiftRegex", .upToNextMajor(from: "1.0.0")),
        .package(url: "https://github.com/httpswift/swifter", .upToNextMajor(from: "1.5.0")),
        .package(url: "https://github.com/Infomaniak/Elegant-Emoji-Picker", .upToNextMajor(from: "1.1.0")),
        .package(url: "https://github.com/Infomaniak/ios-bug-tracker", .upToNextMajor(from: "17.0.0")),
        .package(url: "https://github.com/Infomaniak/ios-core", .upToNextMajor(from: "18.4.3")),
        .package(url: "https://github.com/Infomaniak/ios-core-ui", .upToNextMajor(from: "24.2.0")),
        .package(url: "https://github.com/Infomaniak/ios-create-account", .upToNextMajor(from: "23.2.0")),
        .package(url: "https://github.com/Infomaniak/ios-dependency-injection", .upToNextMajor(from: "2.0.5")),
        .package(url: "https://github.com/Infomaniak/ios-device-check", .upToNextMajor(from: "1.1.1")),
        .package(url: "https://github.com/Infomaniak/ios-features", .upToNextMajor(from: "8.4.3")),
        .package(url: "https://github.com/Infomaniak/ios-login", .upToNextMajor(from: "7.3.0")),
        .package(url: "https://github.com/Infomaniak/ios-notifications", .upToNextMajor(from: "15.0.0")),
        .package(url: "https://github.com/Infomaniak/ios-onboarding", .upToNextMajor(from: "1.1.0")),
        .package(url: "https://github.com/Infomaniak/ios-version-checker", .upToNextMajor(from: "16.0.0")),
        .package(url: "https://github.com/Infomaniak/Popovers", .upToNextMajor(from: "1.3.3")),
        .package(url: "https://github.com/Infomaniak/SwiftSoup", .upToNextMajor(from: "1.3.0")),
        .package(url: "https://github.com/Infomaniak/swift-concurrency", .upToNextMajor(from: "1.0.0")),
        .package(url: "https://github.com/Infomaniak/swift-modal-presentation", .upToNextMajor(from: "1.1.0")),
        .package(url: "https://github.com/Infomaniak/swift-rich-html-editor", .upToNextMajor(from: "3.0.0")),
        .package(url: "https://github.com/johnpatrickmorgan/NavigationBackport", .upToNextMajor(from: "0.8.1")),
        .package(url: "https://github.com/kean/Nuke", .upToNextMajor(from: "12.1.3")),
        .package(url: "https://github.com/markiv/SwiftUI-Shimmer", .upToNextMajor(from: "1.0.1")),
        .package(url: "https://github.com/matomo-org/matomo-sdk-ios", .upToNextMajor(from: "7.5.1")),
        .package(url: "https://github.com/ProxymanApp/atlantis", .upToNextMajor(from: "1.21.0")),
        .package(url: "https://github.com/realm/realm-swift", .upToNextMajor(from: "10.41.0")),
        .package(url: "https://github.com/shaps80/SwiftUIBackports", .upToNextMajor(from: "1.15.1")),
        .package(url: "https://github.com/siteline/SwiftUI-Introspect", .upToNextMajor(from: "26.0.0")),
        .package(url: "https://github.com/exyte/SVGView", .upToNextMajor(from: "1.0.6"))
    ]
)
