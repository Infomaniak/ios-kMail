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

import InfomaniakCoreUI
import SwiftUI

public extension IKPadding {
    // MARK: OnBoarding

    static let onBoardingLogoTop = large
    static let onBoardingBottomButtons = medium

    // MARK: Menu

    static let menuDrawerCell = EdgeInsets(top: intermediate, leading: medium, bottom: intermediate, trailing: medium)
    static let menuDrawerCellWithChevron = EdgeInsets(top: 2, leading: 0, bottom: 2, trailing: medium)
    static let menuDrawerCellSpacing = medium
    static let menuDrawerCellChevronSpacing = intermediate
    static let menuDrawerSubFolder = large

    // MARK: Compose Message

    static let composeViewHeaderCellLargeVertical = intermediate + recipientChip.top
    static let composeViewHeaderHorizontal = medium

    // MARK: Alerts

    static let alertTitleBottom = large
    static let alertDescriptionBottom = large

    // MARK: Misc

    static let floatingButtonBottom = large
    static let bottomSheetHorizontal = large
    static let recipientChip = UIEdgeInsets(top: extraSmall, left: small, bottom: extraSmall, right: small)
    static let aiTextEditor = UIEdgeInsets(top: small, left: small, bottom: small, right: small)
    static let searchFolderCellSpacing = small
}
