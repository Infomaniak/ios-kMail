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
import MailResources
import SwiftUI
import UIKit

public enum BarAppearanceConstants {
    public static let threadViewNavigationBarAppearance: UINavigationBarAppearance = {
        let navigationBarAppearance = UINavigationBarAppearance()
        navigationBarAppearance.configureWithTransparentBackground()
        navigationBarAppearance.backgroundColor = MailResourcesAsset.backgroundColor.color
        navigationBarAppearance.shadowColor = MailResourcesAsset.backgroundColor.color
        return navigationBarAppearance
    }()

    public static let threadViewNavigationBarScrolledAppearance: UINavigationBarAppearance = {
        let navigationBarAppearance = UINavigationBarAppearance()
        navigationBarAppearance.configureWithDefaultBackground()
        navigationBarAppearance.backgroundColor = MailResourcesAsset.backgroundTabBarColor.color
        return navigationBarAppearance
    }()

    public static let threadListNavigationBarAppearance: UINavigationBarAppearance = {
        let navigationBarAppearance = UINavigationBarAppearance()
        navigationBarAppearance.configureWithTransparentBackground()
        navigationBarAppearance.backgroundColor = UserDefaults.shared.accentColor.navBarBackground.color
        navigationBarAppearance.largeTitleTextAttributes = [
            .foregroundColor: MailResourcesAsset.textPrimaryColor.color,
            .font: UIFont.systemFont(ofSize: 22, weight: .semibold)
        ]
        return navigationBarAppearance
    }()

    public static let threadViewToolbarAppearance: UIToolbarAppearance = {
        let toolbarAppearance = UIToolbarAppearance()
        toolbarAppearance.configureWithOpaqueBackground()
        toolbarAppearance.backgroundColor = MailResourcesAsset.backgroundTabBarColor.color
        return toolbarAppearance
    }()
}

public enum UIConstants {
    public static let avatarColors = [
        MailResourcesAsset.yellowColor,
        MailResourcesAsset.coralColor,
        MailResourcesAsset.grassColor,
        MailResourcesAsset.fougereColor,
        MailResourcesAsset.cobaltColor,
        MailResourcesAsset.jeanColor,
        MailResourcesAsset.tropicalColor,
        MailResourcesAsset.mauveColor,
        MailResourcesAsset.princeColor
    ].map(\.color)

    public static let navbarIconSize: CGFloat = 24

    public static let onboardingLogoPaddingTop: CGFloat = 24
    public static let onboardingLogoHeight: CGFloat = 56
    public static let onboardingButtonHeight: CGFloat = 104
    public static let onboardingVerticalTopPadding: CGFloat = 48
    public static let onboardingBottomButtonPadding: CGFloat = 32
    public static let onboardingArrowIconSize: CGFloat = 24

    public static let menuDrawerHorizontalPadding: CGFloat = 24
    public static let menuDrawerVerticalPadding: CGFloat = 14
    public static let menuDrawerSubFolderPadding: CGFloat = 16
    public static let menuDrawerHorizontalItemSpacing: CGFloat = 16
    public static let menuDrawerMaximumSubfolderLevel = 2

    public static let floatingButtonBottomPadding: CGFloat = 24

    public static let progressItemsVerticalPadding: CGFloat = 8
    public static let unreadIconSize: CGFloat = 8
    public static let checkboxSize: CGFloat = 32
    public static let checkmarkSize: CGFloat = 14
    public static let checkboxLargeSize: CGFloat = 40

    public static let checkboxAppearDelay = 0.2
    public static let checkboxDisappearOffsetDelay = 0.35

    public static let selectionBackgroundDefaultLeadingPadding: CGFloat = 8
    public static let selectionBackgroundVerticalPadding: CGFloat = 2

    public static let buttonsRadius: CGFloat = 16
    public static let buttonsIconSize: CGFloat = 16

    public static let composeViewHeaderCellVerticalSpacing: CGFloat = 12
    public static let composeViewHeaderCellLargeVerticalSpacing = composeViewHeaderCellVerticalSpacing + chipInsets.top

    public static let bottomBarVerticalPadding: CGFloat = 8
    public static let bottomBarSmallVerticalPadding: CGFloat = 4
    public static let bottomBarHorizontalMinimumSpace: CGFloat = 8

    public static let bottomSheetHorizontalPadding: CGFloat = 24

    public static let unknownRecipientHorizontalPadding: CGFloat = 8

    public static let autocompletionVerticalPadding: CGFloat = 8

    public static let componentsMaxWidth: CGFloat = 496

    public static let chipInsets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)

    public static func isCompact(horizontalSizeClass: UserInterfaceSizeClass?, verticalSizeClass: UserInterfaceSizeClass?) -> Bool {
        return horizontalSizeClass == .compact || verticalSizeClass == .compact
    }
}
