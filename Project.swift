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

func mainTargetWith(name: String, destinations: [Destination]) -> Target {
    .target(name: name,
            destinations: Set(destinations),
            product: .app,
            bundleId: "com.infomaniak.mail",
            deploymentTargets: Constants.deploymentTarget,
            infoPlist: "Mail/Info.plist",
            sources: "Mail/**",
            resources: [
                "Mail/**/LaunchScreen.storyboard",
                "Mail/Assets.xcassets", // Needed for AppIcon
                "MailResources/**/PrivacyInfo.xcprivacy",
                "Mail/Localizable/**/InfoPlist.strings"
            ],
            entitlements: "MailResources/Mail.entitlements",
            scripts: [
                Constants.swiftlintScript,
                Constants.stripSymbolsScript
            ],
            dependencies: [
                .target(name: "MailCore"),
                .target(name: "MailCoreUI"),
                .target(name: "MailResources"),
                .target(name: "MailNotificationServiceExtension"),
                .target(name: "MailNotificationContentExtension"),
                .target(name: "MailShareExtension"),
                .target(name: "MailAppIntentsExtension"),
                .external(name: "InfomaniakBugTracker"),
                .external(name: "InfomaniakCoreCommonUI"),
                .external(name: "InfomaniakCoreDB"),
                .external(name: "DeviceAssociation"),
                .external(name: "InfomaniakCoreSwiftUI"),
                .external(name: "InfomaniakCore"),
                .external(name: "InfomaniakCreateAccount"),
                .external(name: "InfomaniakDI"),
                .external(name: "InfomaniakDeviceCheck"),
                .external(name: "InterAppLogin"),
                .external(name: "InfomaniakLogin"),
                .external(name: "InfomaniakNotifications"),
                .external(name: "InfomaniakOnboarding"),
                .external(name: "InfomaniakPrivacyManagement"),
                .external(name: "InfomaniakRichHTMLEditor"),
                .external(name: "NavigationBackport"),
                .external(name: "Popovers"),
                .external(name: "Realm"),
                .external(name: "RealmSwift"),
                .external(name: "SwiftModalPresentation"),
                .external(name: "SwiftRegex"),
                .external(name: "SwiftSoup"),
                .external(name: "SwiftUIBackports"),
                .external(name: "SwiftUIIntrospect"),
                .external(name: "VersionChecker"),
                .external(name: "WrappingHStack")
            ],
            settings: .settings(base: Constants.baseSettings))
}

let project = Project(name: "Mail",
                      options: .options(
                          automaticSchemesOptions: .enabled(
                              targetSchemesGrouping: .notGrouped
                          )
                      ),
                      targets: [
                          mainTargetWith(name: "Infomaniak Mail", destinations: [.iPhone, .iPad]),
                          mainTargetWith(name: "Infomaniak Mail Lite", destinations: [.macCatalyst]),
                          .target(name: "MailTests",
                                  destinations: Constants.destinations,
                                  product: .unitTests,
                                  bundleId: "com.infomaniak.mail.tests",
                                  deploymentTargets: Constants.deploymentTarget,
                                  infoPlist: .default,
                                  sources: "MailTests/**",
                                  dependencies: [
                                      .target(name: "Infomaniak Mail"),
                                      .target(name: "MailCore"),
                                      .target(name: "MailResources"),
                                      .external(name: "DeviceAssociation"),
                                      .external(name: "InfomaniakCoreDB"),
                                      .external(name: "InfomaniakCore"),
                                      .external(name: "InfomaniakDI"),
                                      .external(name: "InfomaniakLogin"),
                                      .external(name: "Realm"),
                                      .external(name: "RealmSwift"),
                                      .external(name: "SwiftSoup")
                                  ],
                                  settings: .settings(base: Constants.testSettings)),
                          .target(name: "MailUITests",
                                  destinations: Constants.destinations,
                                  product: .uiTests,
                                  bundleId: "com.infomaniak.mail.uitests",
                                  deploymentTargets: Constants.deploymentTarget,
                                  infoPlist: .default,
                                  sources: "MailUITests/**",
                                  dependencies: [
                                      .target(name: "Infomaniak Mail"),
                                      .target(name: "MailCore"),
                                      .external(name: "InfomaniakCoreUIResources")
                                  ],
                                  settings: .settings(base: Constants.testSettings)),
                          .target(name: "MailShareExtension",
                                  destinations: Constants.destinations,
                                  product: .appExtension,
                                  bundleId: "com.infomaniak.mail.ShareExtension",
                                  deploymentTargets: Constants.deploymentTarget,
                                  infoPlist: .file(path: "MailShareExtension/Info.plist"),
                                  sources: ["MailShareExtension/**",
                                            "Mail/Views/**",
                                            "Mail/Components/**",
                                            "Mail/Helpers/**",
                                            "Mail/Utils/**",
                                            "Mail/Views/**",
                                            "Mail/Proxy/Protocols/**"],
                                  resources: [
                                      "MailShareExtension/**/*.js" // Needed for NSExtensionJavaScriptPreprocessingFile
                                  ],
                                  entitlements: "MailResources/MailExtensions.entitlements",
                                  dependencies: [
                                      .target(name: "MailCore"),
                                      .target(name: "MailCoreUI"),
                                      .target(name: "MailResources"),
                                      .external(name: "DeviceAssociation"),
                                      .external(name: "InfomaniakBugTracker"),
                                      .external(name: "InfomaniakCoreCommonUI"),
                                      .external(name: "InfomaniakCoreDB"),
                                      .external(name: "InfomaniakCoreSwiftUI"),
                                      .external(name: "InfomaniakCore"),
                                      .external(name: "InfomaniakCreateAccount"),
                                      .external(name: "InfomaniakDI"),
                                      .external(name: "InfomaniakLogin"),
                                      .external(name: "InfomaniakNotifications"),
                                      .external(name: "InfomaniakOnboarding"),
                                      .external(name: "InfomaniakPrivacyManagement"),
                                      .external(name: "InfomaniakRichHTMLEditor"),
                                      .external(name: "InfomaniakDeviceCheck"),
                                      .external(name: "InterAppLogin"),
                                      .external(name: "NavigationBackport"),
                                      .external(name: "Popovers"),
                                      .external(name: "Realm"),
                                      .external(name: "RealmSwift"),
                                      .external(name: "SwiftModalPresentation"),
                                      .external(name: "SwiftRegex"),
                                      .external(name: "SwiftSoup"),
                                      .external(name: "SwiftUIBackports"),
                                      .external(name: "SwiftUIIntrospect"),
                                      .external(name: "VersionChecker"),
                                      .external(name: "WrappingHStack")
                                  ],
                                  settings: .settings(base: Constants.baseSettings)),
                          .target(name: "MailNotificationServiceExtension",
                                  destinations: Constants.destinations,
                                  product: .appExtension,
                                  bundleId: "com.infomaniak.mail.NotificationServiceExtension",
                                  deploymentTargets: Constants.deploymentTarget,
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
                                  entitlements: "MailResources/MailExtensions.entitlements",
                                  dependencies: [
                                      .target(name: "MailCore"),
                                      .target(name: "MailResources"),
                                      .external(name: "InfomaniakCore"),
                                      .external(name: "InfomaniakDI"),
                                      .external(name: "InfomaniakLogin"),
                                      .external(name: "InfomaniakNotifications"),
                                      .external(name: "InfomaniakPrivacyManagement"),
                                      .external(name: "RealmSwift")
                                  ],
                                  settings: .settings(base: Constants.baseSettings)),
                          .target(name: "MailNotificationContentExtension",
                                  destinations: Constants.destinations,
                                  product: .appExtension,
                                  bundleId: "com.infomaniak.mail.NotificationContentExtension",
                                  deploymentTargets: Constants.deploymentTarget,
                                  infoPlist: .file(path: "MailNotificationContentExtension/Info.plist"),
                                  sources: ["MailNotificationContentExtension/**",
                                            "Mail/Views/**",
                                            "Mail/Components/**",
                                            "Mail/Helpers/**",
                                            "Mail/Utils/**",
                                            "Mail/Views/**",
                                            "Mail/Proxy/Protocols/**"],
                                  entitlements: "MailResources/MailExtensions.entitlements",
                                  dependencies: [
                                      .target(name: "MailCore"),
                                      .target(name: "MailCoreUI"),
                                      .target(name: "MailResources"),
                                      .sdk(name: "UserNotifications", type: .framework),
                                      .sdk(name: "UserNotificationsUI", type: .framework),
                                      .external(name: "DeviceAssociation"),
                                      .external(name: "InfomaniakBugTracker"),
                                      .external(name: "InfomaniakCoreCommonUI"),
                                      .external(name: "InfomaniakCoreDB"),
                                      .external(name: "InfomaniakCoreSwiftUI"),
                                      .external(name: "InfomaniakCore"),
                                      .external(name: "InfomaniakCreateAccount"),
                                      .external(name: "InfomaniakDI"),
                                      .external(name: "InfomaniakLogin"),
                                      .external(name: "InfomaniakNotifications"),
                                      .external(name: "InfomaniakOnboarding"),
                                      .external(name: "InfomaniakPrivacyManagement"),
                                      .external(name: "InfomaniakRichHTMLEditor"),
                                      .external(name: "InfomaniakDeviceCheck"),
                                      .external(name: "InterAppLogin"),
                                      .external(name: "NavigationBackport"),
                                      .external(name: "Popovers"),
                                      .external(name: "Realm"),
                                      .external(name: "RealmSwift"),
                                      .external(name: "SwiftModalPresentation"),
                                      .external(name: "SwiftRegex"),
                                      .external(name: "SwiftSoup"),
                                      .external(name: "SwiftUIBackports"),
                                      .external(name: "SwiftUIIntrospect"),
                                      .external(name: "VersionChecker"),
                                      .external(name: "WrappingHStack")
                                  ],
                                  settings: .settings(base: Constants.baseSettings)),
                          .target(name: "MailAppIntentsExtension",
                                  destinations: Constants.destinations,
                                  product: .extensionKitExtension,
                                  bundleId: "com.infomaniak.mail.MailAppIntentsExtension",
                                  deploymentTargets: Constants.appIntentsDeploymentTarget,
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
                                      "MailResources/**/*.stringsdict"
                                  ],
                                  entitlements: "MailResources/MailExtensions.entitlements",
                                  dependencies: [
                                      .target(name: "MailCore"),
                                      .external(name: "InfomaniakDI")
                                  ],
                                  settings: .settings(base: Constants.baseSettings)),
                          .target(name: "MailResources",
                                  destinations: Constants.destinations,
                                  product: .framework,
                                  bundleId: "com.infomaniak.mail.resources",
                                  deploymentTargets: Constants.deploymentTarget,
                                  infoPlist: .default,
                                  resources: [
                                      "MailResources/**/*.xcassets",
                                      "MailResources/**/*.strings",
                                      "MailResources/**/*.stringsdict",
                                      "MailResources/**/*.json",
                                      "MailResources/**/*.css",
                                      "MailResources/**/*.js",
                                      "MailResources/**/*.html"
                                  ],
                                  settings: .settings(base: Constants.baseSettings)),
                          .target(name: "MailCore",
                                  destinations: Constants.destinations,
                                  product: .framework,
                                  bundleId: "com.infomaniak.mail.core",
                                  deploymentTargets: Constants.deploymentTarget,
                                  infoPlist: "MailCore/Info.plist",
                                  sources: "MailCore/**",
                                  dependencies: [
                                      .target(name: "MailResources"),
                                      .external(name: "Alamofire"),
                                      .external(name: "Algorithms"),
                                      .external(name: "Atlantis"),
                                      .external(name: "Collections"),
                                      .external(name: "DesignSystem"),
                                      .external(name: "DeviceAssociation"),
                                      .external(name: "InfomaniakBugTracker"),
                                      .external(name: "InfomaniakConcurrency"),
                                      .external(name: "InfomaniakCoreCommonUI"),
                                      .external(name: "InfomaniakCoreDB"),
                                      .external(name: "InfomaniakCoreSwiftUI"),
                                      .external(name: "InfomaniakCoreUIKit"),
                                      .external(name: "InfomaniakCore"),
                                      .external(name: "MyKSuite"),
                                      .external(name: "InfomaniakCreateAccount"),
                                      .external(name: "InfomaniakDI"),
                                      .external(name: "InfomaniakLogin"),
                                      .external(name: "InfomaniakNotifications"),
                                      .external(name: "InfomaniakRichHTMLEditor"),
                                      .external(name: "NukeUI"),
                                      .external(name: "Nuke"),
                                      .external(name: "RealmSwift"),
                                      .external(name: "Realm"),
                                      .external(name: "SnackBar"),
                                      .external(name: "SVGKit"),
                                      .external(name: "Swifter"),
                                      .external(name: "SwiftModalPresentation"),
                                      .external(name: "SwiftRegex"),
                                      .external(name: "SwiftSoup"),
                                      .external(name: "VersionChecker")
                                  ],
                                  settings: .settings(base:
                                      Constants.baseSettings.merging(["OTHER_LDFLAGS": "$(inherited) -ObjC"]))),
                          .target(name: "MailCoreUI",
                                  destinations: Constants.destinations,
                                  product: .framework,
                                  bundleId: "com.infomaniak.mail.coreui",
                                  deploymentTargets: Constants.deploymentTarget,
                                  infoPlist: "MailCoreUI/Info.plist",
                                  sources: "MailCoreUI/**",
                                  dependencies: [
                                      .target(name: "MailCore"),
                                      .target(name: "MailResources"),
                                      .external(name: "InfomaniakCoreCommonUI"),
                                      .external(name: "InfomaniakCoreSwiftUI"),
                                      .external(name: "InfomaniakCoreUIKit"),
                                      .external(name: "InfomaniakCore"),
                                      .external(name: "InfomaniakDI"),
                                      .external(name: "InfomaniakLogin"),
                                      .external(name: "InfomaniakOnboarding"),
                                      .external(name: "NavigationBackport"),
                                      .external(name: "NukeUI"),
                                      .external(name: "Popovers"),
                                      .external(name: "RealmSwift"),
                                      .external(name: "Shimmer"),
                                      .external(name: "SwiftUIBackports"),
                                      .external(name: "SwiftUIIntrospect-Static"),
                                      .external(name: "WrappingHStack")
                                  ],
                                  settings: .settings(base: Constants.baseSettings))
                      ],
                      schemes: [
                          .scheme(name: "Infomaniak Mail",
                                  shared: true,
                                  buildAction: .buildAction(targets: ["Infomaniak Mail"]),
                                  testAction: .targets(["MailTests", "MailUITests"]),
                                  runAction: .runAction(executable: "Infomaniak Mail",
                                                        arguments: .arguments(environmentVariables: [
                                                            "hostname": .environmentVariable(value: "\(ProcessInfo.processInfo.hostName).",
                                                                                             isEnabled: true)
                                                        ])))
                      ],
                      fileHeaderTemplate: .file("file-header-template.txt"))
