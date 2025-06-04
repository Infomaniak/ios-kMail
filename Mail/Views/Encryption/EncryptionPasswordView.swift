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
import MailCore
import MailCoreUI
import MailResources
import SwiftUI

struct EncryptionPasswordView: View {
    let draft: Draft

    var body: some View {
        VStack(alignment: .leading, spacing: IKPadding.huge) {
            VStack(alignment: .leading, spacing: IKPadding.small) {
                Text(MailResourcesStrings.Localizable.encryptedMessageAddPasswordInformation)
                    .textStyle(.bodySecondary)

                Button {
                    // En savoir plus
                } label: {
                    Text(MailResourcesStrings.Localizable.moreInfo)
                        .font(MailTextStyle.bodyMedium.font)
                }
            }

            VStack(alignment: .leading, spacing: IKPadding.small) {
                Text(MailResourcesStrings.Localizable.encryptedPasswordTitle)
                    .textStyle(.bodyMedium)

                Text(MailResourcesStrings.Localizable.encryptedMessagePasswordLabel)
                    .textStyle(.bodySmall)

                HStack {
                    TextField("Password", text: .constant("OUI"))

                    Button {
                        // Generate password
                    } label: {
                        MailResourcesAsset.passwordGenerate.swiftUIImage
                            .resizable()
                            .frame(width: 16, height: 16)
                            .foregroundStyle(MailResourcesAsset.textPrimaryColor.swiftUIColor)
                    }
                }
                .padding(value: .small)
                .background {
                    ZStack {
                        MailResourcesAsset.backgroundColor.swiftUIColor
                            .clipShape(.rect(cornerRadius: IKRadius.small))

                        RoundedRectangle(cornerRadius: IKRadius.small)
                            .stroke(lineWidth: 1)
                            .foregroundColor(MailResourcesAsset.textFieldBorder.swiftUIColor)
                    }
                }

                Button {
                    // Copier
                } label: {
                    Text(MailResourcesStrings.Localizable.buttonCopy)
                        .font(MailTextStyle.bodyMedium.font)
                }
            }
            .padding(value: .large)
            .background {
                MailResourcesAsset.textFieldColor.swiftUIColor
                    .clipShape(.rect(cornerRadius: IKRadius.large))
            }

            VStack(spacing: IKPadding.small) {
                Text(MailResourcesStrings.Localizable.encryptedMessagePasswordConcernedUserTitle)
                    .textStyle(.bodyMedium)

                // TODO: - RecipientChip foreach not-hosted recipient in Draft
            }
        }
        .padding(value: .medium)
        .tint(MailResourcesAsset.sovereignBlueColor.swiftUIColor)
    }
}

#Preview {
    EncryptionPasswordView(draft: Draft())
}
