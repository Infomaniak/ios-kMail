/*
 Infomaniak Mail - iOS App
 Copyright (C) 2024 Infomaniak Network SA

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

import DesignSystem
import SwiftUI

public extension IKPadding {
    // MARK: OnBoarding

    static let onBoardingLogoTop = large
    static let onBoardingBottomButtons = medium

    // MARK: Menu

    static let menuDrawerCell = EdgeInsets(top: small, leading: medium, bottom: small, trailing: medium)
    static let menuDrawerCellWithChevron = EdgeInsets(top: 2, leading: 0, bottom: 2, trailing: medium)
    static let menuDrawerCellSpacing = medium
    static let menuDrawerCellChevronSpacing = small
    static let menuDrawerSubFolder = medium

    // MARK: Compose Message

    static let composeViewHeaderCellLargeVertical = small + recipientChip.top
    static let composeViewHeaderHorizontal = medium

    // MARK: Alerts

    static let alertTitleBottom = large
    static let alertDescriptionBottom = large

    // MARK: Misc

    static let floatingButtonBottom = large
    static let bottomSheetHorizontal = large
    static let recipientChip = UIEdgeInsets(top: micro, left: mini, bottom: micro, right: mini)
    static let aiTextEditor = UIEdgeInsets(top: mini, left: mini, bottom: mini, right: mini)
    static let searchFolderCellSpacing = mini
}
