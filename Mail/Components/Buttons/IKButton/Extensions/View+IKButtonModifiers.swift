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

extension View {
    func ikLinkButton(animation: IKButtonTapAnimation = .opacity, isInlined: Bool = false) -> some View {
        buttonStyle(IKLinkButtonStyle(animation: animation, isInlined: isInlined))
    }

    func ikPlainButton(animation: IKButtonTapAnimation = .opacity) -> some View {
        buttonStyle(IKPlainButtonStyle(animation: animation))
    }

    func ikHugeButton() -> some View {
        buttonStyle(IKHugeButtonStyle())
    }

    func ikFloatingAppButton(isExtended: Bool) -> some View {
        buttonStyle(IKFloatingAppButtonStyle(isExtended: isExtended))
    }
}
