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

import MailCore
import MailResources
import SwiftUI

struct IKLinkButtonStyle: ButtonStyle {
    @Environment(\.ikButtonPrimaryStyle) private var ikButtonPrimaryStyle: any ShapeStyle

    @Environment(\.controlSize) private var controlSize
    @Environment(\.isEnabled) private var isEnabled

    var animation: IKButtonTapAnimation
    var isInlined = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(AnyShapeStyle(foreground(role: configuration.role)))
            .modifier(IKButtonLoadingModifier(isPlain: false))
            .modifier(IKButtonControlSizeModifier())
            .modifier(IKButtonExpandableModifier())
            .modifier(IKButtonLayout(isInlined: isInlined))
            .contentShape(Rectangle())
            .modifier(IKButtonTapAnimationModifier(animation: animation, isPressed: configuration.isPressed))
    }

    private func foreground(role: ButtonRole?) -> any ShapeStyle {
        if !isEnabled {
            return MailTextStyle.bodyMediumOnDisabled.color
        } else if role == .destructive {
            return MailTextStyle.bodyMediumError.color
        } else {
            return ikButtonPrimaryStyle
        }
    }
}

#Preview {
    VStack(spacing: UIPadding.medium) {
        Button {
            /* Preview */
        } label: {
            IKButtonLabel(title: "Standard Button", icon: MailResourcesAsset.pencilPlain)
        }
        .ikLinkButton()

        Button(role: .destructive) {
            /* Preview */
        } label: {
            IKButtonLabel(title: "Destructive Button", icon: MailResourcesAsset.pencilPlain)
        }
        .ikLinkButton()

        Button {
            /* Preview */
        } label: {
            IKButtonLabel(title: "Small Button", icon: MailResourcesAsset.pencilPlain)
        }
        .ikLinkButton()
        .controlSize(.small)

        Button {
            /* Preview */
        } label: {
            IKButtonLabel(title: "Full Width Button", icon: MailResourcesAsset.pencilPlain)
        }
        .ikLinkButton()
        .ikButtonFullWidth(true)

        Button {
            /* Preview */
        } label: {
            IKButtonLabel(title: "Button with different primary color", icon: MailResourcesAsset.pencilPlain)
        }
        .ikLinkButton()
        .ikButtonPrimaryStyle(MailResourcesAsset.aiColor.swiftUIColor)
    }
}
