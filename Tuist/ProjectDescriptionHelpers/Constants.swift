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
        "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "DEBUG"
    ]

    public static let baseSettings = SettingsDictionary()
        .currentProjectVersion("1")
        .marketingVersion("1.9.1")
        .automaticCodeSigning(devTeam: "864VDCS2QY")
        .merging([
            "DERIVE_MACCATALYST_PRODUCT_BUNDLE_IDENTIFIER": SettingValue(stringLiteral: "NO"),
            "TARGETED_DEVICE_FAMILY": SettingValue(stringLiteral: "1,2"),
            "CODE_SIGN_IDENTITY[sdk=macosx*]": SettingValue(stringLiteral: "Apple Development")
        ])

    public static let deploymentTarget = DeploymentTargets.iOS("16.6")

    public static let appIntentsDeploymentTarget = DeploymentTargets.iOS("16.6")

    public static let destinations = Set<Destination>([.iPhone, .iPad, .macCatalyst])

    public static let swiftlintScript = TargetScript.post(
        path: "scripts/lint.sh",
        name: "Swiftlint",
        basedOnDependencyAnalysis: false
    )

    public static let stripSymbolsScript = TargetScript.post(
        path: "scripts/strip_symbols.sh",
        name: "Strip Symbols (Release)",
        inputPaths: [
            "${DWARF_DSYM_FOLDER_PATH}/${EXECUTABLE_NAME}.app.dSYM/Contents/Resources/DWARF/${EXECUTABLE_NAME}"
        ],
        basedOnDependencyAnalysis: false
    )
}
