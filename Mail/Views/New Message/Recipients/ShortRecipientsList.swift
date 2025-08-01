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

import InfomaniakCoreSwiftUI
import MailCore
import MailCoreUI
import RealmSwift
import SwiftUI

struct ShortRecipientsList: View {
    @Environment(\.draftEncryption) private var draftEncryption

    let recipients: RealmSwift.List<Recipient>
    let type: ComposeViewFieldType

    private var chipType: RecipientChipType {
        guard case .encrypted(let passwordSecured) = draftEncryption else { return .default }

        if !passwordSecured {
            let containsNotAutoEncryptedRecipients = recipients.dropFirst().contains {
                !$0.canAutoEncrypt
            }
            return .encrypted(passwordSecured: !containsNotAutoEncryptedRecipients)
        }
        return .encrypted(passwordSecured: true)
    }

    var body: some View {
        HStack(spacing: 8) {
            if let recipient = recipients.first {
                RecipientChip(recipient: recipient, fieldType: type)
                    .disabled(true)
            }

            if recipients.count > 1 {
                MoreRecipientsChip(count: recipients.count - 1, chipType: chipType)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    ShortRecipientsList(recipients: PreviewHelper.sampleRecipientsList, type: .to)
        .environmentObject(PreviewHelper.sampleMailboxManager)
        .environment(\.currentUser, MandatoryEnvironmentContainer(value: PreviewHelper.sampleUser))
}
