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

@available(iOS 16.4, *)
struct ContactCardContentView: View {
    @AppStorage(UserDefaults.shared.key(.accentColor)) private var accentColor = DefaultPreferences.accentColor

    let user: InfomaniakCore.UserProfile

    private var theme: ContactCardTheme {
        let onboardingImage = accentColor == .blue ? MailResourcesAsset.contactCardBlue : MailResourcesAsset.contactCardPink
        return ContactCardTheme(
            primary: accentColor.primary.swiftUIColor,
            secondary: accentColor.secondary.swiftUIColor,
            primaryText: MailResourcesAsset.textPrimaryColor.swiftUIColor,
            secondaryText: MailResourcesAsset.textSecondaryColor.swiftUIColor,
            onAccent: accentColor.onAccent.swiftUIColor,
            background: MailResourcesAsset.backgroundColor.swiftUIColor,
            backgroundTint: MailResourcesAsset.backgroundTertiaryColor.swiftUIColor,
            navBarBackground: accentColor.navBarBackground.swiftUIColor,
            snackbarActionColor: accentColor.snackbarActionColor.swiftUIColor,
            onboardingImage: onboardingImage.swiftUIImage
        )
    }

    var body: some View {
        ContactCardView(
            userProfile: user,
            rootPath: FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier: MailAppTargetAssembly.sharedAppGroupName
            ) ?? URL.temporaryDirectory
        )
        .environment(\.contactCardTheme, theme)
    }
}
