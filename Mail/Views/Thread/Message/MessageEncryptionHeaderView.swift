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
import InfomaniakDI
import MailCore
import MailCoreUI
import MailResources
import RealmSwift
import SwiftUI

struct MessageEncryptionHeaderView: View {
    @ObservedRealmObject var message: Message
    @ObservedRealmObject var mailbox: Mailbox

    private var fromMe: Bool {
        return message.fromMe(currentMailboxEmail: mailbox.email)
    }

    private var encryptionTitle: String {
        guard fromMe else {
            return MailResourcesStrings.Localizable.encryptedMessageHeader
        }

        if let passwordValidity = message.cryptPasswordValidity {
            return MailResourcesStrings.Localizable.encryptedMessageHeaderPasswordExpiryDate(passwordValidity)
        }

        return MailResourcesStrings.Localizable.encryptedMessageHeader
    }

    var body: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading) {
                HStack(alignment: .top, spacing: IKPadding.small) {
                    MailResourcesAsset.lockSquareFill.swiftUIImage
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 16)
                        .foregroundStyle(MailResourcesAsset.iconSovereignBlueColor)
                    Text(encryptionTitle)
                        .font(MailTextStyle.labelSecondary.font)
                        .foregroundStyle(MailResourcesAsset.textHeaderSovereignBlueColor.swiftUIColor)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack {
                    if message.cryptPasswordValidity != nil {
                        Button(MailResourcesStrings.Localizable.encryptedButtonSeeConcernedRecipients) {
                            // See recipients
                        }
                    }
                }
                .tint(MailResourcesAsset.textHeaderSovereignBlueColor.swiftUIColor)
                .buttonStyle(.ikBorderless(isInlined: true))
                .controlSize(.small)
                .padding(.leading, 16 + IKPadding.small)
            }
            .padding(.vertical, value: .mini)
            .padding(.horizontal, value: .medium)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MailResourcesAsset.backgroundSovereignBlueColor.swiftUIColor)
    }
}

#Preview {
    MessageEncryptionHeaderView(message: PreviewHelper.sampleMessage, mailbox: PreviewHelper.sampleMailbox)
}
