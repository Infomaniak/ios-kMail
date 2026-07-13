/*
 Infomaniak Mail - iOS App
 Copyright (C) 2025 Infomaniak Network SA

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import ContactCard
import InfomaniakCore
import MailCore
import MailResources
import SwiftUI

struct ContactCardContentView: View {
    @Environment(\.colorScheme) private var colorScheme

    let user: InfomaniakCore.UserProfile

    var body: some View {
        if #available(iOS 16.4, *) {
            let baseUserAccentColor = UserDefaults.shared.accentColor
            let onBoardingImageByTheme = onBoardingImageByTheme()

            let myTheme = ContactCardTheme(
                primary: baseUserAccentColor.primary.swiftUIColor,
                secondary: baseUserAccentColor.secondary.swiftUIColor,
                primaryText: MailResourcesAsset.textPrimaryColor.swiftUIColor,
                secondaryText: MailResourcesAsset.textSecondaryColor.swiftUIColor,
                onAccent: baseUserAccentColor.onAccent.swiftUIColor,
                background: MailResourcesAsset.backgroundColor.swiftUIColor,
                backgroundTint: MailResourcesAsset.backgroundTertiaryColor.swiftUIColor,
                navBarBackground: baseUserAccentColor.navBarBackground.swiftUIColor,
                snackbarActionColor: baseUserAccentColor.snackbarActionColor.swiftUIColor,
                onboardingImage: onBoardingImageByTheme
            )
            ContactCardView(
                userProfile: user,
                rootPath: FileManager.default.containerURL(
                    forSecurityApplicationGroupIdentifier: MailAppTargetAssembly.sharedAppGroupName
                ) ?? URL.temporaryDirectory
            )
            .id(UserDefaults.shared.accentColor)
            .environment(\.contactCardTheme, myTheme)
        }
    }

    private func isEffectiveDarkMode() -> Bool {
        switch UserDefaults.shared.theme {
        case .dark:
            return true
        case .light:
            return false
        case .system:
            return colorScheme == .dark
        }
    }

    private func onBoardingImageByTheme() -> Image {
        let isDark = isEffectiveDarkMode()
        let isBlue = UserDefaults.shared.accentColor == .blue

        var asset: MailResourcesImages
        switch (isDark, isBlue) {
        case (true, true):
            asset = MailResourcesAsset.contactCardBleuDark
        case (true, false):
            asset = MailResourcesAsset.contactCardPinkDark
        case (false, true):
            asset = MailResourcesAsset.contactCardBleu
        case (false, false):
            asset = MailResourcesAsset.contactCardPink
        }

        return asset.swiftUIImage
    }
}
