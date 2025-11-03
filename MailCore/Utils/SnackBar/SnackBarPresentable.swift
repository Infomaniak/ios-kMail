/*
 Infomaniak Mail - iOS App
 Copyright (C) 2023 Infomaniak Network SA

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
import InfomaniakCoreCommonUI
import SnackBar
import UIKit

public struct SnackBarPresenter: IKSnackBarPresentable {
    /// Set to display the snack bar is a specific context, like
    private let contextView: UIView?

    public init(contextView: UIView? = nil) {
        self.contextView = contextView
    }

    public func show(message: String) {
        show(message: message, contextView: contextView)
    }

    public func show(message: String, action: IKSnackBar.Action?) {
        show(message: message, action: action, contextView: nil)
    }

    public func show(
        message: String,
        duration: SnackBar.Duration = .lengthLong,
        action: IKSnackBar.Action? = nil,
        contextView: UIView? = nil
    ) {
        Task { @MainActor in
            IKSnackBar.showMailSnackBar(
                message: message,
                duration: duration,
                action: action,
                contextView: contextView
            )
        }
    }
}
