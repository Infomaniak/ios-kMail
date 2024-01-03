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
    static let navbarIconPadding: CGFloat = 16
    // size of 3 icons + 5 paddings between them
    static let navbarIconsSpace: CGFloat = navbarIconSize * 3 + (navbarIconPadding * 5)

    static let onboardingLogoHeight: CGFloat = 56
    static let onboardingButtonHeight: CGFloat = 104

    static let menuDrawerMaxWidth: CGFloat = 352
    static let menuDrawerTrailingSpacing: CGFloat = 64
    static let menuDrawerLogoHeight: CGFloat = 48
    static let menuDrawerQuotaSize: CGFloat = 40

    static let unreadIconSize: CGFloat = 8
    static let checkboxSize: CGFloat = 32
    static let checkmarkSize: CGFloat = 14
    static let checkboxLargeSize: CGFloat = 40

    static let bottomBarHorizontalMinimumSpace: CGFloat = 8

    static let buttonsRadius: CGFloat = 16
    static let buttonsIconSize: CGFloat = 16

    static let componentsMaxWidth: CGFloat = 496

    static let buttonExtraLargeHeight: CGFloat = 64
    static let buttonLargeHeight: CGFloat = 56
    static let buttonRegularHeight: CGFloat = 40

    static let aiPromptSheetHeight: CGFloat = 232

    static let avatarBorderLineWidth: CGFloat = 1
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

    static func applyComposeViewStyle(to toolbar: UIToolbar) {
        toolbar.isTranslucent = false

        toolbar.setShadowImage(UIImage(), forToolbarPosition: .any)
        toolbar.layer.shadowColor = UIColor.black.cgColor
        toolbar.layer.shadowOpacity = 0.1
        toolbar.layer.shadowOffset = CGSize(width: 1, height: 1)
        toolbar.layer.shadowRadius = 2
        toolbar.layer.masksToBounds = false
    }
}

// MARK: - Misc

public extension UIConstants {
    static let menuDrawerMaximumSubFolderLevel = 2

    static let scrollObserverThreshold: ClosedRange<CGFloat> = -50 ... 50
}
