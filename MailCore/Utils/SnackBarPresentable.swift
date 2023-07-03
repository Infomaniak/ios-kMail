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
import InfomaniakCoreUI
import SnackBar
import UIKit

// TODO: move to core UI
// TODO: Use our type not the lib
public extension IKSnackBar {
    enum Duration: Equatable {
        case lengthLong
        case lengthShort
        case infinite
        case custom(CGFloat)

        var value: CGFloat {
            switch self {
            case .lengthLong:
                return 3.5
            case .lengthShort:
                return 2
            case .infinite:
                return -1
            case .custom(let duration):
                return duration
            }
        }
    }
}

public protocol SnackBarPresentable {
    func show(message: String)
    func show(
        message: String,
        duration: SnackBar.Duration,
        action: IKSnackBar.Action?,
        anchor: CGFloat,
        contextView: UIView?
    )
}

public final class SnackBarPresenter: SnackBarPresentable {
    /// Set to display the snack bar is a specific context, like
    private var contextView: UIView?

    public init(contextView: UIView? = nil) {
        self.contextView = contextView
    }

    public func show(message: String) {
        show(message: message, contextView: contextView)
    }

    public func show(
        message: String,
        duration: SnackBar.Duration = .lengthLong,
        action: IKSnackBar.Action? = nil,
        anchor: CGFloat = 0,
        contextView: UIView? = nil
    ) {
        Task { @MainActor in
            IKSnackBar.showSnackBar(
                message: message,
                duration: duration,
                action: action,
                anchor: anchor,
                contextView: contextView
            )
        }
    }
}
