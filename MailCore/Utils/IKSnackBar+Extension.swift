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
import InfomaniakCore
import InfomaniakCoreUI
import InfomaniakDI
import MailResources
import SnackBar

public extension SnackBarStyle {
    static func mailStyle(withAnchor anchor: CGFloat) -> SnackBarStyle {
        var snackBarStyle = SnackBarStyle()
        snackBarStyle.anchor = anchor
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

public class SnackBarAvoider {
    public var snackBarInset: CGFloat = 0

    public init() { /* Needed to init */ }

    public func addAvoider(inset: CGFloat) {
        if inset != snackBarInset {
            snackBarInset = inset
        }
    }

    public func removeAvoider() {
        snackBarInset = 0
    }
}

public extension IKSnackBar {
    @discardableResult
    @MainActor
    static func showSnackBar(
        message: String,
        duration: SnackBar.Duration = .lengthLong,
        action: IKSnackBar.Action? = nil,
        anchor: CGFloat = 0
    ) -> IKSnackBar? {
        @LazyInjectService var avoider: SnackBarAvoider
        let snackbar = IKSnackBar.make(message: message, duration: duration, style: .mailStyle(withAnchor: avoider.snackBarInset), elevation: 0)
        if let action = action {
            snackbar?.setAction(action).show()
        } else {
            snackbar?.show()
        }
        return snackbar
    }

    @discardableResult
    @MainActor
    static func showCancelableSnackBar(
        message: String,
        cancelSuccessMessage: String,
        duration: SnackBar.Duration = .lengthLong,
        undoRedoAction: UndoRedoAction,
        mailboxManager: MailboxManager
    ) -> IKSnackBar? {
        return IKSnackBar.showSnackBar(
            message: message,
            duration: duration,
            action: .init(title: MailResourcesStrings.Localizable.buttonCancel) {
                Task {
                    do {
                        @InjectService var matomo: MatomoUtils
                        matomo.track(eventWithCategory: .snackbar, name: "undo")

                        let cancelled = try await mailboxManager.apiFetcher.undoAction(resource: undoRedoAction.undo.resource)

                        if cancelled {
                            IKSnackBar.showSnackBar(message: cancelSuccessMessage)
                            try await undoRedoAction.redo?()
                        }
                    } catch {
                        IKSnackBar.showSnackBar(message: error.localizedDescription)
                    }
                }
            }
        )
    }
}
