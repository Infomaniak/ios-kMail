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
    public enum Options {
        /// 48pt spacing
        case large
        /// 24pt spacing
        case medium
        /// 16pt spacing
        case regular
        /// 12pt spacing
        case intermediate
        /// 8pt spacing
        case small
        /// 4pt spacing
        case verySmall

        var value: CGFloat {
            switch self {
            case .large:
                return UIPadding.large
            case .medium:
                return UIPadding.medium
            case .regular:
                return UIPadding.regular
            case .intermediate:
                return UIPadding.intermediate
            case .small:
                return UIPadding.small
            case .verySmall:
                return UIPadding.verySmall
            }
        }
    }

    /// 48pt spacing
    public static let large: CGFloat = 48
    /// 24pt spacing
    public static let medium: CGFloat = 24
    /// 16pt spacing
    public static let regular: CGFloat = 16
    /// 12pt spacing
    public static let intermediate: CGFloat = 12
    /// 8pt spacing
    public static let small: CGFloat = 8
    /// 4pt spacing
    public static let verySmall: CGFloat = 4
}

public extension UIPadding {
    // MARK: OnBoarding

    static let onBoardingLogoTop = medium
    static let onBoardingBottomButtons = regular

    // MARK: Menu

    static let menuDrawerCell = EdgeInsets(top: intermediate, leading: regular, bottom: intermediate, trailing: regular)
    static let menuDrawerCellSpacing = regular
    static let menuDrawerCellChevronSpacing = intermediate
    static let menuDrawerSubFolder = medium

    // MARK: Compose Message

    static let composeViewHeaderCellLargeVertical = intermediate + recipientChip.top
    static let composeViewHeaderHorizontal = regular

    // MARK: Alerts

    static let alertTitleBottom = medium
    static let alertDescriptionBottom = medium

    // MARK: Misc

    static let floatingButtonBottom = medium
    static let bottomSheetHorizontal = medium
    static let recipientChip = UIEdgeInsets(top: verySmall, left: small, bottom: verySmall, right: small)
    static let aiTextEditor = UIEdgeInsets(top: small, left: small, bottom: small, right: small)
    static let searchFolderCellSpacing = small
}

public extension View {
    func padding(_ edges: Edge.Set = .all, value: UIPadding.Options) -> some View {
        padding(edges, value.value)
    }
}
