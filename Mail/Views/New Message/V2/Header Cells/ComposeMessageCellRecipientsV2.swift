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

struct ComposeMessageCellRecipientsV2: View {
    @Binding var recipients: RealmSwift.List<Recipient>
    @Binding var showAllRecipientsFields: Bool

    let type: ComposeViewFieldType

    var body: some View {
        HStack {
            Text(type.title)
                .textStyle(.bodySecondary)

            RecipientField(
                recipients: $recipients,
                autocompletion: .constant([]),
                unknownRecipientAutocompletion: .constant(""),
                addRecipientHandler: .constant(nil),
                type: type
            )

            if type == .to {
                Spacer()
                ChevronButton(isExpanded: $showAllRecipientsFields)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ComposeMessageCellRecipientsV2_Previews: PreviewProvider {
    static var previews: some View {
        ComposeMessageCellRecipientsV2(recipients: .constant([
            PreviewHelper.sampleRecipient1, PreviewHelper.sampleRecipient2, PreviewHelper.sampleRecipient3
        ].toRealmList()), showAllRecipientsFields: .constant(false), type: .to)
    }
}
