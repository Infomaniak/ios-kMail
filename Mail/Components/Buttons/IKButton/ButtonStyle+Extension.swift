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

extension ButtonStyle where Self == IKLinkButtonStyle {
    static func ikLink(isInlined: Bool = false) -> IKLinkButtonStyle {
        return IKLinkButtonStyle(isInlined: isInlined)
    }
}

extension ButtonStyle where Self == IKPlainButtonStyle {
    static var ikPlain: IKPlainButtonStyle {
        return IKPlainButtonStyle()
    }
}

extension ButtonStyle where Self == IKFloatingAppButtonStyle {
    static func ikFloatingAppButton(isExtended: Bool) -> IKFloatingAppButtonStyle {
        return IKFloatingAppButtonStyle(isExtended: isExtended)
    }
}

extension ButtonStyle where Self == IKSquareButtonStyle {
    static var ikSquare: IKSquareButtonStyle {
        return IKSquareButtonStyle()
    }
}
