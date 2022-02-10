import ProjectDescription

let project = Project(name: "Mail",
                      packages: [
                          .package(url: "https://github.com/Infomaniak/ios-login.git", .upToNextMajor(from: "1.4.0")),
                          .package(url: "https://github.com/ProxymanApp/atlantis", .upToNextMajor(from: "1.3.0"))
                      ],
                      targets: [
                          Target(name: "Mail",
                                 platform: .iOS,
                                 product: .app,
                                 bundleId: "com.infomaniak.mail",
                                 deploymentTarget: .iOS(targetVersion: "15.0", devices: [.iphone, .ipad]),
                                 infoPlist: "Mail/Info.plist",
                                 sources: "Mail/**",
                                 resources: [
                                     "Mail/**/*.storyboard",
                                     "Mail/**/*.xcassets",
                                     "Mail/**/*.strings",
                                     "Mail/**/*.stringsdict",
                                     "Mail/**/*.xib"
//                                     "mail/**/*.json",
//                                     "mail/**/*.css"
                                 ],
                                 dependencies: [
                                     .package(product: "Atlantis"),
                                     .package(product: "InfomaniakLogin")
                                 ]),
                          Target(name: "MailTests",
                                 platform: .iOS,
                                 product: .unitTests,
                                 bundleId: "com.infomaniak.mail.tests",
                                 infoPlist: "MailTests/Info.plist",
                                 sources: "MailTests/**",
                                 dependencies: [
                                     .target(name: "Mail")
                                 ])
                      ])
