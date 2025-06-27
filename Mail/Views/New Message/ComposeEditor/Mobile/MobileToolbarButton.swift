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
import InfomaniakCoreSwiftUI
import MailCore
import MailResources
import SwiftUI

struct MobileToolbarButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    let isActivated: Bool
    var customTint: Color?

    private var foreground: Color {
        return isActivated ? EditorMobileToolbarView.colorSecondary : customTint ?? EditorMobileToolbarView.colorPrimary
    }

    private var background: Color {
        return isActivated ? customTint ?? EditorMobileToolbarView.colorPrimary : EditorMobileToolbarView.colorSecondary
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .labelStyle(.iconOnly)
            .padding(value: .mini)
            .background(background, in: .rect(cornerRadius: IKRadius.small))
            .foregroundStyle(foreground)
            .padding(.vertical, value: .micro)
            .opacity(configuration.isPressed || !isEnabled ? 0.2 : 1)
    }
}

struct MobileToolbarButton: View {
    let text: String
    let icon: Image
    let isActivated: Bool
    let customTint: Color?
    let action: @MainActor () -> Void

    init(
        toolbarAction: EditorToolbarAction,
        isActivated: Bool,
        customTint: Color? = nil,
        perform actionToPerform: @escaping @MainActor () -> Void
    ) {
        text = toolbarAction.accessibilityLabel
        icon = toolbarAction.icon.swiftUIImage
        self.customTint = customTint
        self.isActivated = isActivated
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
        }
        .buttonStyle(MobileToolbarButtonStyle(isActivated: isActivated, customTint: customTint))
    }
}
