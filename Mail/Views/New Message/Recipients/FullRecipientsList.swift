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

import DesignSystem
import InfomaniakCoreCommonUI
import InfomaniakCoreSwiftUI
import InfomaniakDI
import MailCore
import MailCoreUI
import RealmSwift
import SwiftUI

struct FullRecipientsList: View {
    @Environment(\.currentUser) private var currentUser
    @EnvironmentObject private var mailboxManager: MailboxManager

    @Binding var recipients: RealmSwift.List<Recipient>

    @FocusState var focusedField: ComposeViewFieldType?

    let type: ComposeViewFieldType

    var body: some View {
        BackportedFlowLayout(recipients, verticalSpacing: IKPadding.mini, horizontalSpacing: IKPadding.mini) { recipient in
            RecipientChip(recipient: recipient, fieldType: type, focusedField: _focusedField) {
                remove(recipient: recipient)
            } switchFocusHandler: {
                switchFocus()
            }
            .focused($focusedField, equals: .chip(type.hashValue, recipient))
            .environmentObject(mailboxManager)
            .environment(\.currentUser, currentUser)
        }
    }

    @MainActor private func remove(recipient: Recipient) {
        @InjectService var matomo: MatomoUtils
        matomo.track(eventWithCategory: .newMessage, name: "deleteRecipient")

        if recipient.isExternal(mailboxManager: mailboxManager) {
            matomo.track(eventWithCategory: .externals, name: "deleteRecipient")
        }

        guard let recipientAt = $recipients.wrappedValue.firstIndex(where: { $0.id == recipient.id }) else { return }
        withAnimation {
            $recipients.remove(at: recipientAt)
        }
    }

    private func switchFocus() {
        guard case .chip(let hash, let recipient) = focusedField else { return }

        if recipient == recipients.last {
            focusedField = type
        } else if let recipientIndex = recipients.firstIndex(of: recipient) {
            focusedField = .chip(hash, recipients[recipientIndex + 1])
        }
    }
}

#Preview {
    FullRecipientsList(recipients: .constant(PreviewHelper.sampleRecipientsList), type: .to)
        .environmentObject(PreviewHelper.sampleMailboxManager)
        .environment(\.currentUser, MandatoryEnvironmentContainer(value: PreviewHelper.sampleUser))
}
