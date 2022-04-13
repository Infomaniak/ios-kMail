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

import ProjectDescription

let deploymentTarget = DeploymentTarget.iOS(targetVersion: "15.0", devices: [.iphone, .ipad])

let project = Project(name: "Mail",
                      packages: [
                          .package(url: "https://github.com/Infomaniak/ios-login.git", .upToNextMajor(from: "1.4.0")),
                          .package(url: "https://github.com/Infomaniak/ios-core.git", .branch("mail")),
                          .package(url: "https://github.com/ProxymanApp/atlantis", .upToNextMajor(from: "1.3.0")),
                          .package(url: "https://github.com/Alamofire/Alamofire.git", .upToNextMajor(from: "5.2.2")),
                          .package(url: "https://github.com/CocoaLumberjack/CocoaLumberjack.git", .upToNextMajor(from: "3.7.0")),
                          .package(url: "https://github.com/realm/realm-cocoa", .upToNextMajor(from: "10.0.0")),
                          .package(url: "https://github.com/matomo-org/matomo-sdk-ios.git", .upToNextMajor(from: "7.5.1")),
                          .package(url: "https://github.com/ProxymanApp/atlantis", .upToNextMajor(from: "1.16.0")),
                          .package(url: "https://github.com/siteline/SwiftUI-Introspect.git", .upToNextMajor(from: "0.1.4"))
                      ],
                      targets: [
                          Target(name: "Mail",
                                 platform: .iOS,
                                 product: .app,
                                 bundleId: "com.infomaniak.mail",
                                 deploymentTarget: deploymentTarget,
                                 infoPlist: "Mail/Info.plist",
                                 sources: "Mail/**",
                                 resources: [
                                     "Mail/**/*.storyboard"
                                 ],
                                 scripts: [
                                     .post(path: "scripts/lint.sh", name: "Swiftlint")
                                 ],
                                 dependencies: [
                                     .target(name: "MailCore"),
                                     .target(name: "MailResources"),
                                     .package(product: "MatomoTracker"),
                                     .package(product: "Atlantis"),
                                     .package(product: "Introspect")
                                 ]),
                          Target(name: "MailTests",
                                 platform: .iOS,
                                 product: .unitTests,
                                 bundleId: "com.infomaniak.mail.tests",
                                 infoPlist: "MailTests/Info.plist",
                                 sources: "MailTests/**",
                                 dependencies: [
                                     .target(name: "Mail")
                                 ]),
                          Target(
                              name: "MailUITests",
                              platform: .iOS,
                              product: .uiTests,
                              bundleId: "com.infomaniak.mail.uitests",
                              infoPlist: "MailTests/Info.plist",
                              sources: "MailUITests/**",
                              dependencies: [
                                  .target(name: "Mail")
                              ]
                          ),
                          Target(
                              name: "MailResources",
                              platform: .iOS,
                              product: .staticLibrary,
                              bundleId: "com.infomaniak.mail.resources",
                              deploymentTarget: deploymentTarget,
                              infoPlist: .default,
                              resources: [
                                  "MailResources/**/*.xcassets"
                              ]
                          ),
                          Target(
                              name: "MailCore",
                              platform: .iOS,
                              product: .framework,
                              bundleId: "com.infomaniak.mail.core",
                              deploymentTarget: deploymentTarget,
                              infoPlist: "MailCore/Info.plist",
                              sources: "MailCore/**",
                              dependencies: [
                                  .target(name: "MailResources"),
                                  .package(product: "Alamofire"),
                                  .package(product: "Atlantis"),
                                  .package(product: "InfomaniakCore"),
                                  .package(product: "InfomaniakLogin"),
                                  .package(product: "CocoaLumberjackSwift"),
                                  .package(product: "RealmSwift")
                              ]
                          )
                      ],
                      fileHeaderTemplate: .file("file-header-template.txt"))
