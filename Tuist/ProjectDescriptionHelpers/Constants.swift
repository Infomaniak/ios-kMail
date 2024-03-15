/*
 Infomaniak kDrive - iOS App
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

public enum Constants {
    public static let testSettings: [String: SettingValue] = [
        "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "TEST DEBUG"
    ]

    public static let baseSettings = SettingsDictionary()
        .currentProjectVersion("1")
        .marketingVersion("1.1.3")
        .automaticCodeSigning(devTeam: "864VDCS2QY")
        .merging(["DERIVE_MACCATALYST_PRODUCT_BUNDLE_IDENTIFIER": SettingValue(stringLiteral: "NO")])

    public static let deploymentTarget = DeploymentTarget.iOS(targetVersion: "15.0", devices: [.iphone, .ipad, .mac])

    public static let appIntentsDeploymentTarget = DeploymentTarget.iOS(targetVersion: "16.4", devices: [.iphone, .ipad, .mac])

    public static let swiftlintScript = TargetScript.post(path: "scripts/lint.sh", name: "Swiftlint")
}
