/*
 Infomaniak Mail - iOS App
 Copyright (C) 2022 Infomaniak Network SA

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

import Foundation
import InfomaniakCore
import InfomaniakCoreCommonUI
import InfomaniakDI
import MailResources
import SnackBar
import UIKit

public extension SnackBarStyle {
    static func mailStyle(withAnchor anchor: CGFloat) -> SnackBarStyle {
        var snackBarStyle = SnackBarStyle()
        snackBarStyle.anchor = anchor
        snackBarStyle.maxWidth = 600
        snackBarStyle.padding = 16
        snackBarStyle.inViewPadding = 16
        snackBarStyle.cornerRadius = 8
        snackBarStyle.background = MailResourcesAsset.textPrimaryColor.color
        snackBarStyle.textColor = MailResourcesAsset.elementsColor.color
        snackBarStyle.font = .systemFont(ofSize: 16)
        snackBarStyle.actionTextColor = UserDefaults.shared.accentColor.snackbarActionColor.color
        snackBarStyle.actionTextColorAlpha = 1
        snackBarStyle.actionFont = .systemFont(ofSize: 16, weight: .medium)
        return snackBarStyle
    }
}

public extension IKSnackBar {
    /// Call this method to display a `SnackBar`
    /// - Parameters:
    ///   - message: The message to display
    ///   - duration: The time the message should be displayed
    ///   - action: The action to perform if any
    ///   - contextView: Set a context view, when displaying in extension mode for eg.
    /// - Returns: An IKSnackBar if any
    @discardableResult
    @MainActor
    static func showMailSnackBar(
        message: String,
        duration: SnackBar.Duration = .lengthLong,
        action: IKSnackBar.Action? = nil,
        contextView: UIView? = nil
    ) -> IKSnackBar? {
        @LazyInjectService var avoider: IKSnackBarAvoider

        let snackbar: IKSnackBar?
        if let contextView {
            snackbar = IKSnackBar.make(
                in: contextView,
                message: message,
                duration: duration,
                style: .mailStyle(withAnchor: avoider.snackBarInset)
            )
        } else {
            snackbar = IKSnackBar.make(
                message: message,
                duration: duration,
                style: .mailStyle(withAnchor: avoider.snackBarInset),
                elevation: 0
            )
        }

        guard let snackbar else {
            return nil
        }

        if let action {
            snackbar.setAction(action).show()
        } else {
            snackbar.show()
        }
        return snackbar
    }

    @discardableResult
    @MainActor
    static func showCancelableSnackBar(
        message: String,
        cancelSuccessMessage: String,
        duration: SnackBar.Duration = .lengthLong,
        undoAction: UndoAction
    ) -> IKSnackBar? {
        return IKSnackBar.showMailSnackBar(
            message: message,
            duration: duration,
            action: .init(title: MailResourcesStrings.Localizable.buttonCancel) {
                @InjectService var snackbarPresenter: IKSnackBarPresentable
                Task {
                    do {
                        @InjectService var matomo: MatomoUtils
                        matomo.track(eventWithCategory: .snackbar, name: "undo")

                        let undoSucceeded = try await undoAction.undo()

                        if undoSucceeded {
                            snackbarPresenter.show(message: cancelSuccessMessage)
                            _ = try await undoAction.afterUndo?()
                        }
                    } catch {
                        snackbarPresenter.show(message: error.localizedDescription)
                    }
                }
            }
        )
    }
}
