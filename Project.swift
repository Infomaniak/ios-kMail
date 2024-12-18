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
                      options: .options(
                          automaticSchemesOptions: .enabled(
                            targetSchemesGrouping: .byNameSuffix(
                              build: Set(["Mail", "Extension"]),
                              test: Set(["Tests"]),
                              run: Set(["Mail", "Extension"])
                            )
                          )
                      ),
                      targets: [
                          .target(name: "Infomaniak Mail",
                                  destinations: Constants.destinations,
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
                                      .target(name: "MailNotificationServiceExtension"),
                                      .target(name: "MailNotificationContentExtension"),
                                      .target(name: "MailShareExtension"),
                                      .target(name: "MailAppIntentsExtension")
                                  ],
                                  settings: .settings(base: Constants.baseSettings),
                                  environmentVariables: [
                                      "hostname": .environmentVariable(value: "\(ProcessInfo.processInfo.hostName).",
                                                                       isEnabled: true)
                                  ]),
                          .target(name: "MailTests",
                                  destinations: Constants.destinations,
                                  product: .unitTests,
                                  bundleId: "com.infomaniak.mail.tests",
                                  deploymentTargets: Constants.deploymentTarget,
                                  infoPlist: .default,
                                  sources: "MailTests/**",
                                  dependencies: [
                                      .target(name: "Infomaniak Mail")
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
                                      .target(name: "MailResources")
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
                                  entitlements: "MailShareExtension/ShareExtension.entitlements",
                                  scripts: [Constants.swiftlintScript],
                                  dependencies: [
                                      .target(name: "MailCore"),
                                      .target(name: "MailCoreUI")
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
                                  entitlements: "MailResources/Mail.entitlements",
                                  dependencies: [
                                      .target(name: "MailCore")
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
                                  entitlements: "MailNotificationContentExtension/MailNotificationContentExtension.entitlements",
                                  scripts: [Constants.swiftlintScript],
                                  dependencies: [
                                      .target(name: "MailCore"),
                                      .target(name: "MailCoreUI"),
                                      .sdk(name: "UserNotifications", type: .framework),
                                      .sdk(name: "UserNotificationsUI", type: .framework)
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
                                  entitlements: "MailResources/Mail.entitlements",
                                  dependencies: [
                                      .target(name: "MailCore")
                                  ],
                                  settings: .settings(base: Constants.baseSettings)),
                          .target(name: "MailResources",
                                  destinations: Constants.destinations,
                                  product: .staticLibrary,
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
                                      .external(name: "Algorithms"),
                                      .external(name: "Alamofire"),
                                      .external(name: "Atlantis"),
                                      .external(name: "InfomaniakCore"),
                                      .external(name: "InfomaniakCoreDB"),
                                      .external(name: "InfomaniakCoreCommonUI"),
                                      .external(name: "InfomaniakCoreSwiftUI"),
                                      .external(name: "InfomaniakCoreUIKit"),
                                      .external(name: "InfomaniakLogin"),
                                      .external(name: "InfomaniakDI"),
                                      .external(name: "InfomaniakConcurrency"),
                                      .external(name: "InfomaniakNotifications"),
                                      .external(name: "InfomaniakBugTracker"),
                                      .external(name: "InfomaniakCreateAccount"),
                                      .external(name: "RealmSwift"),
                                      .external(name: "SwiftRegex"),
                                      .external(name: "Nuke"),
                                      .external(name: "NukeUI"),
                                      .external(name: "SwiftSoup"),
                                      .external(name: "Swifter"),
                                      .external(name: "VersionChecker"),
                                      .external(name: "SwiftModalPresentation"),
                                      .external(name: "SVGKit"),
                                      .external(name: "InfomaniakRichHTMLEditor")
                                  ],
                                  settings: .settings(base: Constants.baseSettings)),
                          .target(name: "MailCoreUI",
                                  destinations: Constants.destinations,
                                  product: .framework,
                                  bundleId: "com.infomaniak.mail.coreui",
                                  deploymentTargets: Constants.deploymentTarget,
                                  infoPlist: "MailCoreUI/Info.plist",
                                  sources: "MailCoreUI/**",
                                  dependencies: [
                                      .target(name: "MailCore"),
                                      .external(name: "SwiftUIIntrospect-Static"),
                                      .external(name: "InfomaniakOnboarding"),
                                      .external(name: "Shimmer"),
                                      .external(name: "WrappingHStack"),
                                      .external(name: "NavigationBackport"),
                                      .external(name: "Popovers"),
                                      .external(name: "SwiftUIBackports")
                                  ],
                                  settings: .settings(base: Constants.baseSettings))
                      ],
                      fileHeaderTemplate: .file("file-header-template.txt"))
