import ProjectDescription

let project = Project(name: "mail",
                      packages: [
                          .package(url: "https://github.com/Infomaniak/ios-login.git", .upToNextMajor(from: "1.4.0")),
                          .package(url: "https://github.com/ProxymanApp/atlantis", .upToNextMajor(from: "1.3.0"))
                      ],
                      targets: [
                          Target(name: "mail",
                                 platform: .iOS,
                                 product: .app,
                                 bundleId: "com.infomaniak.mail",
                                 deploymentTarget: .iOS(targetVersion: "15.0", devices: [.iphone, .ipad]),
                                 infoPlist: "mail/Info.plist",
                                 sources: "mail/**",
                                 resources: [
                                     "mail/**/*.storyboard",
                                     "mail/**/*.xcassets",
                                     "mail/**/*.strings",
                                     "mail/**/*.stringsdict",
                                     "mail/**/*.xib",
//                                     "mail/**/*.json",
//                                     "mail/**/*.css"
                                 ],
                                 dependencies: [
                                     .package(product: "Atlantis"),
                                     .package(product: "InfomaniakLogin")
                                 ]),
                          Target(name: "mailTests",
                                 platform: .iOS,
                                 product: .unitTests,
                                 bundleId: "com.infomaniak.mail.tests",
                                 infoPlist: "mailTests/Info.plist",
                                 sources: "mailTests/**",
                                 dependencies: [
                                     .target(name: "mail")
                                 ])
                      ])

