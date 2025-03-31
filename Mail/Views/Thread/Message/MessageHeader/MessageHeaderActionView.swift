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

struct MessageHeaderActionView<Content: View>: View {
    let iconSize: CGFloat = 16
    let icon: Image
    let message: String
    let isFirst: Bool

    @ViewBuilder var actions: () -> Content

    var body: some View {
        VStack(alignment: .leading) {
            if isFirst {
                IKDivider()
            }
            VStack(alignment: .leading) {
                HStack(spacing: IKPadding.small) {
                    icon
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: iconSize)
                        .foregroundStyle(MailResourcesAsset.textSecondaryColor)
                    Text(message)
                        .textStyle(.labelSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack {
                    actions()
                }
                .buttonStyle(.ikBorderless(isInlined: true))
                .controlSize(.small)
                .padding(.leading, iconSize + IKPadding.small)
            }
            .padding(.bottom, value: .micro)
            .padding(.top, isFirst ? IKPadding.micro : 0)
            .padding(.horizontal, value: .medium)
            IKDivider()
        }
    }
}

#Preview {
    VStack {
        MessageHeaderActionView(
            icon: MailResourcesAsset.emailActionWarning.swiftUIImage,
            message: MailResourcesStrings.Localizable.alertBlockedImagesDescription,
            isFirst: true
        ) {
            Button(MailResourcesStrings.Localizable.alertBlockedImagesDisplayContent) { /* Preview */ }
                .buttonStyle(.ikBorderless(isInlined: true))
                .controlSize(.small)
        }

        MessageHeaderActionView(
            icon: MailResourcesAsset.emailActionWarning.swiftUIImage,
            message: MailResourcesStrings.Localizable.alertBlockedImagesDescription,
            isFirst: false
        ) {
            Button(MailResourcesStrings.Localizable.alertBlockedImagesDisplayContent) { /* Preview */ }
                .buttonStyle(.ikBorderless(isInlined: true))
                .controlSize(.small)
        }
    }
}
