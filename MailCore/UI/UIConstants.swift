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

public enum UIConstants {}

// MARK: - Paddings

public extension UIConstants {
    static let paddingLarge: CGFloat = 48
    static let paddingMedium: CGFloat = 24
    static let paddingRegular: CGFloat = 16
    static let paddingIntermediate: CGFloat = 12
    static let paddingSmall: CGFloat = 8
    static let paddingVerySmall: CGFloat = 4
}

// MARK: - Color sets

public extension UIConstants {
    static let avatarColors = [
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
}

// MARK: - Elements sizing

public extension UIConstants {
    static let navbarIconSize: CGFloat = 24

    static let onboardingLogoHeight: CGFloat = 56
    static let onboardingButtonHeight: CGFloat = 104
    static let onboardingArrowIconSize: CGFloat = 24

    static let menuDrawerMaxWidth: CGFloat = 352
    static let menuDrawerTrailingSpacing: CGFloat = 64
    static let menuDrawerLogoHeight: CGFloat = 48
    static let menuDrawerSubFolderPadding: CGFloat = 24

    static let unreadIconSize: CGFloat = 8
    static let checkboxSize: CGFloat = 32
    static let checkmarkSize: CGFloat = 14
    static let checkboxLargeSize: CGFloat = 40

    static let bottomBarHorizontalMinimumSpace: CGFloat = 8

    static let buttonsRadius: CGFloat = 16
    static let buttonsIconSize: CGFloat = 16

    static let componentsMaxWidth: CGFloat = 496

    static let chipInsets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
}

// MARK: - Animations

public extension UIConstants {
    static let checkboxAppearDelay = 0.2
    static let checkboxDisappearOffsetDelay = 0.35
}

// MARK: - Utils

public extension UIConstants {
    static func isCompact(horizontalSizeClass: UserInterfaceSizeClass?, verticalSizeClass: UserInterfaceSizeClass?) -> Bool {
        return horizontalSizeClass == .compact || verticalSizeClass == .compact
    }
}

// MARK: - Misc

public extension UIConstants {
    static let menuDrawerMaximumSubfolderLevel = 2

    // TODO: Sort elements below (wip)

    static let onboardingLogoPaddingTop: CGFloat = 24
    static let onboardingVerticalTopPadding: CGFloat = 48
    static let onboardingBottomButtonPadding: CGFloat = 32

    static let menuDrawerHorizontalPadding: CGFloat = 24
    static let menuDrawerVerticalPadding: CGFloat = 14
    static let menuDrawerHorizontalItemSpacing: CGFloat = 16

    static let floatingButtonBottomPadding: CGFloat = 24

    static let progressItemsVerticalPadding: CGFloat = 8

    static let selectionBackgroundDefaultLeadingPadding: CGFloat = 8
    static let selectionBackgroundVerticalPadding: CGFloat = 2

    static let composeViewHeaderCellVerticalSpacing: CGFloat = 12
    static let composeViewHeaderCellLargeVerticalSpacing = composeViewHeaderCellVerticalSpacing + chipInsets.top

    static let bottomBarVerticalPadding: CGFloat = 8
    static let bottomBarSmallVerticalPadding: CGFloat = 4

    static let bottomSheetHorizontalPadding: CGFloat = 24

    static let actionsViewSpacing: CGFloat = 12
    static let actionsViewHorizontalPadding: CGFloat = 8
    static let actionsViewCellHorizontalPadding: CGFloat = 24

    static let unknownRecipientHorizontalPadding: CGFloat = 8

    static let autocompletionVerticalPadding: CGFloat = 8
}
