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

import InfomaniakCoreSwiftUI
import SwiftUI

struct MobileToolbarButton: View {
    let text: String
    let icon: Image
    let action: @MainActor () -> Void

    init(toolbarAction: EditorToolbarAction, perform actionToPerform: @escaping @MainActor () -> Void) {
        text = toolbarAction.accessibilityLabel
        icon = toolbarAction.icon.swiftUIImage
        action = actionToPerform
    }

    var body: some View {
        Button(action: action) {
            Label {
                Text(text)
            } icon: {
                icon
                    .iconSize(EditorMobileToolbarView.iconSize)
            }
            .labelStyle(.iconOnly)
        }
    }
}
