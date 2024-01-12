/*
 Infomaniak Mail - iOS App
 Copyright (C) 2022 Infomaniak Network SA

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import Foundation
import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(name: "Mail",
                      packages: [
                          .package(url: "https://github.com/apple/swift-algorithms", .upToNextMajor(from: "1.2.0")),
                          .package(url: "https://github.com/Infomaniak/ios-login", .upToNextMajor(from: "4.0.0")),
                          .package(url: "https://github.com/Infomaniak/ios-dependency-injection", .upToNextMajor(from: "1.1.11")),
                          .package(url: "https://github.com/Infomaniak/swift-concurrency", .upToNextMajor(from: "0.0.4")),
                          .package(
                              url: "https://github.com/Infomaniak/ios-core",
                              .revision("360cd7a262621a9bbd91200909e75a94adab6dab")
                          ),
                          .package(url: "https://github.com/Infomaniak/ios-core-ui", .upToNextMajor(from: "2.5.3")),
                          .package(url: "https://github.com/Infomaniak/ios-notifications", .upToNextMajor(from: "3.0.0")),
                          .package(url: "https://github.com/Infomaniak/ios-create-account", .upToNextMajor(from: "1.1.0")),
                          .package(url: "https://github.com/Infomaniak/ios-bug-tracker", .upToNextMajor(from: "2.0.0")),
                          .package(url: "https://github.com/Infomaniak/SQRichTextEditor", .upToNextMajor(from: "1.1.1")),
                          .package(url: "https://github.com/Infomaniak/SwiftSoup", .upToNextMajor(from: "1.1.0")),
                          .package(url: "https://github.com/Infomaniak/ios-version-checker", .upToNextMajor(from: "1.0.1")),
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
                      ],
                      targets: [
                          Target(name: "Mail",
                                 platform: .iOS,
                                 product: .app,
                                 bundleId: "com.infomaniak.mail",
                                 deploymentTarget: Constants.deploymentTarget,
                                 infoPlist: "Mail/Info.plist",
                                 sources: "Mail/**",
                                 resources: [
                                     "Mail/**/*.storyboard",
                                     "MailResources/**/*.xcassets",
                                     "MailResources/**/*.strings",
                                     "MailResources/**/*.stringsdict",
                                     "MailResources/**/*.json",
                                     "MailResources/**/*.css",
                                     "MailResources/**/*.js",
                                     "MailResources/**/*.html"
                                 ],
                                 entitlements: "MailResources/Mail.entitlements",
                                 scripts: [Constants.swiftlintScript],
                                 dependencies: [
                                     .target(name: "MailCore"),
                                     .target(name: "MailNotificationServiceExtension"),
                                     .target(name: "MailShareExtension"),
                                     .target(name: "MailAppIntentsExtension"),
                                     .package(product: "SwiftUIIntrospect-Static"),
                                     .package(product: "SQRichTextEditor"),
                                     .package(product: "Shimmer"),
                                     .package(product: "WrappingHStack"),
                                     .package(product: "Lottie"),
                                     .package(product: "NavigationBackport"),
                                     .package(product: "Popovers"),
                                     .package(product: "SwiftUIBackports")
                                 ],
                                 settings: .settings(base: Constants.baseSettings),
                                 environment: ["hostname": "\(ProcessInfo.processInfo.hostName)."]),
                          Target(name: "MailTests",
                                 platform: .iOS,
                                 product: .unitTests,
                                 bundleId: "com.infomaniak.mail.tests",
                                 infoPlist: "MailTests/Info.plist",
                                 sources: "MailTests/**",
                                 dependencies: [
                                     .target(name: "Mail")
                                 ],
                                 settings: .settings(base: Constants.testSettings)),
                          Target(name: "MailUITests",
                                 platform: .iOS,
                                 product: .uiTests,
                                 bundleId: "com.infomaniak.mail.uitests",
                                 infoPlist: "MailTests/Info.plist",
                                 sources: "MailUITests/**",
                                 dependencies: [
                                     .target(name: "Mail")
                                 ],
                                 settings: .settings(base: Constants.testSettings)),
                          Target(name: "MailShareExtension",
                                 platform: .iOS,
                                 product: .appExtension,
                                 bundleId: "com.infomaniak.mail.ShareExtension",
                                 deploymentTarget: Constants.deploymentTarget,
                                 infoPlist: .file(path: "MailShareExtension/Info.plist"),
                                 sources: ["MailShareExtension/**",
                                           "Mail/Views/**",
                                           "Mail/Components/**",
                                           "Mail/Helpers/**",
                                           "Mail/Utils/**",
                                           "Mail/Views/**",
                                           "Mail/Proxy/Protocols/**"],
                                 resources: [
                                     "MailShareExtension/Base.lproj/MainInterface.storyboard",
                                     "Mail/**/*.storyboard",
                                     "MailResources/**/*.xcassets",
                                     "MailResources/**/*.strings",
                                     "MailResources/**/*.stringsdict",
                                     "MailResources/**/*.json",
                                     "MailResources/**/*.css",
                                     "MailResources/**/*.js"
                                 ],
                                 entitlements: "MailShareExtension/ShareExtension.entitlements",
                                 scripts: [Constants.swiftlintScript],
                                 dependencies: [
                                     .target(name: "MailCore"),
                                     .package(product: "SwiftUIIntrospect-Static"),
                                     .package(product: "SQRichTextEditor"),
                                     .package(product: "Shimmer"),
                                     .package(product: "WrappingHStack"),
                                     .package(product: "Lottie"),
                                     .package(product: "NavigationBackport"),
                                     .package(product: "Popovers"),
                                     .package(product: "SwiftUIBackports")
                                 ],
                                 settings: .settings(base: Constants.baseSettings)),
                          Target(name: "MailNotificationServiceExtension",
                                 platform: .iOS,
                                 product: .appExtension,
                                 bundleId: "com.infomaniak.mail.NotificationServiceExtension",
                                 deploymentTarget: Constants.deploymentTarget,
                                 infoPlist: .extendingDefault(with: [
                                     "AppIdentifierPrefix": "$(AppIdentifierPrefix)",
                                     "CFBundleDisplayName": "$(PRODUCT_NAME)",
                                     "CFBundleShortVersionString": "$(MARKETING_VERSION)",
                                     "CFBundleVersion": "$(CURRENT_PROJECT_VERSION)",
                                     "NSExtension": [
                                         "NSExtensionPointIdentifier": "com.apple.usernotifications.service",
                                         "NSExtensionPrincipalClass": "$(PRODUCT_MODULE_NAME).NotificationService"
                                     ]
                                 ]),
                                 sources: "MailNotificationServiceExtension/**",
                                 entitlements: "MailResources/Mail.entitlements",
                                 dependencies: [
                                     .target(name: "MailCore")
                                 ],
                                 settings: .settings(base: Constants.baseSettings)),
                          Target(name: "MailAppIntentsExtension",
                                 platform: .iOS,
                                 product: .extensionKitExtension,
                                 bundleId: "com.infomaniak.mail.MailAppIntentsExtension",
                                 deploymentTarget: Constants.appIntentsDeploymentTarget,
                                 infoPlist: .extendingDefault(with: [
                                    "AppIdentifierPrefix": "$(AppIdentifierPrefix)",
                                    "CFBundleDisplayName": "$(PRODUCT_NAME)",
                                    "CFBundleShortVersionString": "$(MARKETING_VERSION)",
                                    "CFBundleVersion": "$(CURRENT_PROJECT_VERSION)",
                                    "EXAppExtensionAttributes": [
                                        "EXExtensionPointIdentifier": "com.apple.appintents-extension"
                                    ]
                                 ]),
                                 sources: "MailAppIntentsExtension/**",
                                 resources: [
                                    "MailResources/**/*.strings",
                                    "MailResources/**/*.stringsdict",
                                 ],
                                 entitlements: "MailResources/Mail.entitlements",
                                 dependencies: [
                                    .target(name: "MailCore")
                                 ],
                                 settings: .settings(base: Constants.baseSettings)),
                          Target(name: "MailResources",
                                 platform: .iOS,
                                 product: .staticLibrary,
                                 bundleId: "com.infomaniak.mail.resources",
                                 deploymentTarget: Constants.deploymentTarget,
                                 infoPlist: .default,
                                 resources: [
                                     "MailResources/**/*.xcassets",
                                     "MailResources/**/*.strings",
                                     "MailResources/**/*.stringsdict",
                                     "MailResources/**/*.json",
                                     "MailResources/**/*.css",
                                     "MailResources/**/*.js"
                                 ],
                                 settings: .settings(base: Constants.baseSettings)),
                          Target(name: "MailCore",
                                 platform: .iOS,
                                 product: .framework,
                                 bundleId: "com.infomaniak.mail.core",
                                 deploymentTarget: Constants.deploymentTarget,
                                 infoPlist: "MailCore/Info.plist",
                                 sources: "MailCore/**",
                                 dependencies: [
                                     .target(name: "MailResources"),
                                     .package(product: "Algorithms"),
                                     .package(product: "Alamofire"),
                                     .package(product: "Atlantis"),
                                     .package(product: "InfomaniakCore"),
                                     .package(product: "InfomaniakCoreUI"),
                                     .package(product: "InfomaniakLogin"),
                                     .package(product: "InfomaniakDI"),
                                     .package(product: "InfomaniakConcurrency"),
                                     .package(product: "InfomaniakNotifications"),
                                     .package(product: "InfomaniakBugTracker"),
                                     .package(product: "InfomaniakCreateAccount"),
                                     .package(product: "CocoaLumberjackSwift"),
                                     .package(product: "RealmSwift"),
                                     .package(product: "SwiftRegex"),
                                     .package(product: "Nuke"),
                                     .package(product: "NukeUI"),
                                     .package(product: "SwiftSoup"),
                                     .package(product: "Swifter"),
                                     .package(product: "VersionChecker")
                                 ],
                                 settings: .settings(base: Constants.baseSettings))
                      ],
                      fileHeaderTemplate: .file("file-header-template.txt"))
