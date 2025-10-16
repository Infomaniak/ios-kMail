/*
 Infomaniak Mail - iOS App
 Copyright (C) 2025 Infomaniak Network SA

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
import InfomaniakCoreCommonUI
import InfomaniakDI
import MailCoreUI
import SwiftUI

struct BottomToolbarSnackbarAvoider: ViewModifier {
    @LazyInjectService var avoider: IKSnackBarAvoider

    func body(content: Content) -> some View {
        if UserDefaults.shared.autoAdvance != .listOfThread {
            content
                .overlay {
                    ViewGeometry(key: BottomToolbarHeightKey.self, property: \.size.height)
                }
                .onPreferenceChange(BottomToolbarHeightKey.self) { value in
                    avoider.addAvoider(inset: value + IKPadding.mini)
                }
        } else {
            content
        }
    }
}
