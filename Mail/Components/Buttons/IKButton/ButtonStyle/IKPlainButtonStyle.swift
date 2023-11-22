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

struct IKPlainButtonStyle: ButtonStyle {
    @Environment(\.ikButtonPrimaryStyle) private var ikButtonPrimaryStyle: any ShapeStyle
    @Environment(\.ikButtonSecondaryStyle) private var ikButtonSecondaryStyle: any ShapeStyle

    @Environment(\.controlSize) private var controlSize
    @Environment(\.isEnabled) private var isEnabled

    private var foreground: any ShapeStyle {
        guard isEnabled else { return MailTextStyle.bodyMediumOnDisabled.color }
        return ikButtonSecondaryStyle
    }

    private var background: any ShapeStyle {
        guard isEnabled else { return MailResourcesAsset.textTertiaryColor.swiftUIColor }
        return ikButtonPrimaryStyle
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(AnyShapeStyle(foreground))
            .modifier(IKButtonLoadingModifier(isPlain: true))
            .modifier(IKButtonExpandableModifier())
            .modifier(IKButtonControlSizeModifier())
            .modifier(IKButtonLayout())
            .background(AnyShapeStyle(background), in: RoundedRectangle(cornerRadius: UIConstants.buttonsRadius))
            .modifier(IKButtonTapAnimationModifier(isPressed: configuration.isPressed))
    }
}

#Preview {
    VStack(spacing: UIPadding.medium) {
        Button {
            /* Preview */
        } label: {
            IKButtonLabel(title: "Standard Button", icon: MailResourcesAsset.pencilPlain)
        }
        .buttonStyle(IKPlainButtonStyle())

        Button {
            /* Preview */
        } label: {
            IKButtonLabel(title: "Loading Button", icon: MailResourcesAsset.pencilPlain)
        }
        .buttonStyle(IKPlainButtonStyle())
        .ikButtonLoading(true)

        Button {
            /* Preview */
        } label: {
            IKButtonLabel(title: "Large Button", icon: MailResourcesAsset.pencilPlain)
        }
        .buttonStyle(IKPlainButtonStyle())
        .controlSize(.large)

        Button {
            /* Preview */
        } label: {
            IKButtonLabel(title: "Full Width Button", icon: MailResourcesAsset.pencilPlain)
        }
        .buttonStyle(IKPlainButtonStyle())
        .ikButtonLoading(true)

        Button {
            /* Preview */
        } label: {
            IKButtonLabel(title: "Button with different colors", icon: MailResourcesAsset.pencilPlain)
        }
        .buttonStyle(IKPlainButtonStyle())
        .ikButtonPrimaryStyle(MailResourcesAsset.aiColor.swiftUIColor)
        .ikButtonSecondaryStyle(MailResourcesAsset.backgroundSecondaryColor.swiftUIColor)
    }
}
