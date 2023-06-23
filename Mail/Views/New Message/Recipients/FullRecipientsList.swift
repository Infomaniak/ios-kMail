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
import RealmSwift
import SwiftUI
import WrappingHStack

struct FullRecipientsList: View {
    @Binding var recipients: RealmSwift.List<Recipient>

    @FocusState var focusedField: ComposeViewFieldType?

    let type: ComposeViewFieldType

    var body: some View {
        WrappingHStack(recipients.indices, spacing: .constant(8), lineSpacing: 8) { i in
            RecipientChip(recipient: recipients[i], fieldType: type, focusedField: _focusedField) {
                remove(recipientAt: i)
            } switchFocusHandler: {
                switchFocus()
            }
            .focused($focusedField, equals: .chip(type.hashValue, recipients[i]))
        }
        .alignmentGuide(.newMessageCellAlignment) { d in d[.top] + 21 }
    }

    @MainActor private func remove(recipientAt: Int) {
        withAnimation {
            $recipients.remove(at: recipientAt)
        }
    }

    private func switchFocus() {
        guard case let .chip(hash, recipient) = focusedField else { return }

        if recipient == recipients.last {
            focusedField = type
        } else if let recipientIndex = recipients.firstIndex(of: recipient) {
            focusedField = .chip(hash, recipients[recipientIndex + 1])
        }
    }
}

struct FullRecipientsList_Previews: PreviewProvider {
    static var previews: some View {
        FullRecipientsList(recipients: .constant(PreviewHelper.sampleRecipientsList), type: .to)
    }
}
