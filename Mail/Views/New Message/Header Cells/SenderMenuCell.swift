/*
 Infomaniak Mail - iOS App
 Copyright (C) 2024 Infomaniak Network SA

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

import InfomaniakCore
import InfomaniakCoreUI
import InfomaniakDI
import MailCore
import MailResources
import SwiftUI

struct SenderMenuCell: View {
    @LazyInjectService private var matomo: MatomoUtils

    @EnvironmentObject private var draftContentManager: DraftContentManager
    @EnvironmentObject private var mailboxManager: MailboxManager

    @Binding var currentSignature: Signature?

    let signature: Signature?

    private var signatureLabel: String {
        signature?.formatted(style: .option) ?? MailResourcesStrings.Localizable.selectSignatureNone
    }

    var body: some View {
        Button {
            matomo.track(eventWithCategory: .newMessage, name: "switchIdentity")

            withAnimation {
                currentSignature = signature
            }
            draftContentManager.updateSignature(with: signature)
        } label: {
            Label {
                Text(signatureLabel)
            } icon: {
                if signature == currentSignature {
                    MailResourcesAsset.check.swiftUIImage
                }
            }
            .accessibilityHint(MailResourcesStrings.Localizable.contentDescriptionButtonSelectSignature)

            Text(signature?.senderEmailIdn ?? mailboxManager.mailbox.emailIdn)
        }
    }
}

#Preview {
    SenderMenuCell(currentSignature: .constant(nil), signature: Signature())
}
