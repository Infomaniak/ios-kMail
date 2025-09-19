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
                "Mail/Assets.xcassets", // Needed for LaunchScreen
                "MailResources/**/PrivacyInfo.xcprivacy",
                "Mail/Localizable/**/InfoPlist.strings",
                "Mail/AppIcon.icon"
            ],
            entitlements: "MailResources/Mail.entitlements",
            scripts: [
                Constants.swiftlintScript,
                Constants.stripSymbolsScript
            ],
            dependencies: [
                .target(name: "MailCore"),
                .target(name: "MailCoreUI"),
                .target(name: "MailResources")
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
                                      "MailResources/**/*.lottie",
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
                                      .target(name: "MailResources")
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
                                      .target(name: "MailResources")
                                  ],
                                  settings: .settings(base: Constants.baseSettings))
                      ],
                      schemes: [
                          .scheme(name: "Infomaniak Mail",
                                  shared: true,
                                  buildAction: .buildAction(targets: ["Infomaniak Mail"]),
                                  runAction: .runAction(executable: "Infomaniak Mail",
                                                        arguments: .arguments(environmentVariables: [
                                                            "hostname": .environmentVariable(value: "\(ProcessInfo.processInfo.hostName).",
                                                                                             isEnabled: true)
                                                        ])))
                      ],
                      fileHeaderTemplate: .file("file-header-template.txt"))
