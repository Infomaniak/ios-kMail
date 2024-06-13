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

import InfomaniakCoreUI
import InfomaniakDI
import MailCore
import MailCoreUI
import RealmSwift
import SwiftUI
import WrappingHStack

struct FullRecipientsList: View {
    @LazyInjectService private var matomo: MatomoUtils

    @EnvironmentObject private var mailboxManager: MailboxManager
    @Binding var recipients: RealmSwift.List<Recipient>

    @FocusState var focusedField: ComposeViewFieldType?

    let type: ComposeViewFieldType

    var body: some View {
        WrappingHStack(recipients.indices, spacing: .constant(UIPadding.small), lineSpacing: UIPadding.small) { i in
            RecipientChip(recipient: recipients[i], fieldType: type, focusedField: _focusedField) {
                remove(recipientAt: i)
            } switchFocusHandler: {
                switchFocus()
            }
            .focused($focusedField, equals: .chip(type.hashValue, recipients[i]))
            .environmentObject(mailboxManager)
        }
    }

    @MainActor private func remove(recipientAt: Int) {
        matomo.track(eventWithCategory: .newMessage, name: "deleteRecipient")
        if recipients[recipientAt].isExternal(mailboxManager: mailboxManager) {
            matomo.track(eventWithCategory: .externals, name: "deleteRecipient")
        }

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
}
