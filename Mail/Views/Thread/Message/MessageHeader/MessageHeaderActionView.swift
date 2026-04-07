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

import DesignSystem
import InfomaniakCoreSwiftUI
import MailCore
import MailCoreUI
import MailResources
import SwiftUI

struct MessageHeaderDivider: View {
    var body: some View {
        Divider()
            .frame(width: 1, height: 20)
            .overlay(MailResourcesAsset.elementsColor.swiftUIColor)
    }
}

struct MessageHeaderActionView<AnimationView: View, Content: View>: View {
    let iconSize: CGFloat = 16
    let icon: Image?
    let animationView: AnimationView
    let message: String
    let showTopSeparator: Bool
    let showBottomSeparator: Bool
    let iconColor: Color
    let textColor: Color
    let shouldDisplayActions: Bool
    let actions: () -> Content

    init(
        icon: Image,
        message: String,
        showTopSeparator: Bool = true,
        showBottomSeparator: Bool,
        iconColor: Color = MailResourcesAsset.textSecondaryColor.swiftUIColor,
        textColor: Color = MailResourcesAsset.textSecondaryColor.swiftUIColor,
        shouldDisplayActions: Bool = true,
        @ViewBuilder actions: @escaping () -> Content
    ) where AnimationView == EmptyView {
        self.icon = icon
        self.message = message
        self.showTopSeparator = showTopSeparator
        self.showBottomSeparator = showBottomSeparator
        self.iconColor = iconColor
        self.textColor = textColor
        self.shouldDisplayActions = shouldDisplayActions
        animationView = EmptyView()
        self.actions = actions
    }

    init(
        message: String,
        showTopSeparator: Bool = true,
        showBottomSeparator: Bool,
        iconColor: Color = MailResourcesAsset.textSecondaryColor.swiftUIColor,
        textColor: Color = MailResourcesAsset.textSecondaryColor.swiftUIColor,
        shouldDisplayActions: Bool = true,
        @ViewBuilder animationView: () -> AnimationView,
        @ViewBuilder actions: @escaping () -> Content
    ) {
        icon = nil
        self.message = message
        self.showTopSeparator = showTopSeparator
        self.showBottomSeparator = showBottomSeparator
        self.iconColor = iconColor
        self.textColor = textColor
        self.shouldDisplayActions = shouldDisplayActions
        self.animationView = animationView()
        self.actions = actions
    }

    private var topPadding: CGFloat {
        guard showTopSeparator || showBottomSeparator else {
            return IKPadding.mini
        }
        return showTopSeparator ? IKPadding.micro : 0
    }

    private var bottomPadding: CGFloat {
        guard showTopSeparator || showBottomSeparator else {
            return IKPadding.mini
        }
        return showBottomSeparator ? IKPadding.micro : 0
    }

    var body: some View {
        VStack(alignment: .leading) {
            if showTopSeparator {
                IKDivider()
            }

            VStack(alignment: .leading) {
                HStack(spacing: IKPadding.small) {
                    if let icon {
                        icon
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: iconSize)
                            .foregroundStyle(iconColor)
							.accessibilityHidden(true)
                    } else {
                        animationView
                            .aspectRatio(contentMode: .fit)
                            .frame(width: iconSize)
                    }

                    Text(message)
                        .font(MailTextStyle.label.font)
                        .foregroundStyle(textColor)
                }

                if shouldDisplayActions {
                    actions()
                        .buttonStyle(.ikBorderless(isInlined: true))
                        .controlSize(.small)
                        .padding(.leading, iconSize + IKPadding.small)
                }
            }
            .padding(.bottom, bottomPadding)
            .padding(.top, topPadding)
            .padding(.horizontal, value: .medium)

            if showBottomSeparator {
                IKDivider()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    VStack {
        MessageHeaderActionView(
            icon: MailResourcesAsset.emailActionWarning.swiftUIImage,
            message: MailResourcesStrings.Localizable.alertBlockedImagesDescription,
            showBottomSeparator: false
        ) {
            Button(MailResourcesStrings.Localizable.alertBlockedImagesDisplayContent) { /* Preview */ }
                .buttonStyle(.ikBorderless(isInlined: true))
                .controlSize(.small)
        }

        MessageHeaderActionView(
            icon: MailResourcesAsset.emailActionWarning.swiftUIImage,
            message: MailResourcesStrings.Localizable.alertBlockedImagesDescription,
            showBottomSeparator: false
        ) {
            Button(MailResourcesStrings.Localizable.alertBlockedImagesDisplayContent) { /* Preview */ }
                .buttonStyle(.ikBorderless(isInlined: true))
                .controlSize(.small)
        }

        MessageHeaderActionView(
            icon: MailResourcesAsset.lockSquareFill.swiftUIImage,
            message: MailResourcesStrings.Localizable.encryptedMessageHeaderPasswordExpiryDate(Date()),
            showTopSeparator: false,
            showBottomSeparator: false,
            iconColor: MailResourcesAsset.iconSovereignBlueColor.swiftUIColor,
            textColor: MailResourcesAsset.textHeaderSovereignBlueColor.swiftUIColor
        ) {
            Button(MailResourcesStrings.Localizable.encryptedButtonSeeConcernedRecipients) { /* Preview */ }
        }
    }
}
