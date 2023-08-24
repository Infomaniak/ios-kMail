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

import SwiftUI

public enum UIPadding {
    public static let large: CGFloat = 48
    public static let medium: CGFloat = 24
    public static let regular: CGFloat = 16
    public static let intermediate: CGFloat = 12
    public static let small: CGFloat = 8
    public static let verySmall: CGFloat = 4
}

public extension UIPadding {
    // MARK: OnBoarding

    static let onBoardingLogoTop = medium
    static let onBoardingBottomButtons = medium

    // MARK: Menu

    static let menuDrawerCell = regular
    static let menuDrawerCellSpacing = regular
    static let menuDrawerCellChevronSpacing = intermediate
    static let menuDrawerSubFolder = medium

    // MARK: Actions

    static let actionsSpacing = intermediate
    static let actionsHorizontal = small
    static let actionsCellHorizontal = medium

    // MARK: Misc

    static let floatingButtonBottom = medium
    static let bottomSheetHorizontal = medium
    static let composeViewHeaderCellLargeVertical = intermediate + UIConstants.recipientChipInsets.top
}
