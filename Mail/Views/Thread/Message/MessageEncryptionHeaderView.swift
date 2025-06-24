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

    @State private var isShowingRecipients = false

    private var fromMe: Bool {
        return message.fromMe(currentMailboxEmail: mailbox.email)
    }

    private var encryptionTitle: String {
        guard fromMe else {
            return MailResourcesStrings.Localizable.encryptedMessageHeader
        }

        if let passwordValidity = message.cryptPasswordValidity {
            let date = passwordValidity.formatted(date: .numeric, time: .omitted)
            return MailResourcesStrings.Localizable.encryptedMessageHeaderPasswordExpiryDate(date)
        }

        return MailResourcesStrings.Localizable.encryptedMessageHeader
    }

    var body: some View {
        MessageHeaderActionView(
            icon: MailResourcesAsset.lockSquareFill.swiftUIImage,
            message: encryptionTitle,
            showTopSeparator: false,
            showBottomSeparator: false,
            iconColor: MailResourcesAsset.iconSovereignBlueColor.swiftUIColor,
            textColor: MailResourcesAsset.textHeaderSovereignBlueColor.swiftUIColor
        ) {
            if message.cryptPasswordValidity != nil {
                Button(MailResourcesStrings.Localizable.encryptedButtonSeeConcernedRecipients) {
                    isShowingRecipients = true
                }
                .tint(MailResourcesAsset.textHeaderSovereignBlueColor.swiftUIColor)
            }
        }
        .background(MailResourcesAsset.backgroundSovereignBlueColor.swiftUIColor)
        .floatingPanel(
            isPresented: $isShowingRecipients,
            title: MailResourcesStrings.Localizable.encryptedRecipientRequiringPasswordTitle(0)
        ) {
            EncryptionConcernedRecipientsView()
        }
    }
}

#Preview {
    MessageEncryptionHeaderView(message: PreviewHelper.sampleMessage, mailbox: PreviewHelper.sampleMailbox)
}
