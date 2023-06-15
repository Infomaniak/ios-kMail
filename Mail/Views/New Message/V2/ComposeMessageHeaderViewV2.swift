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

struct ComposeMessageHeaderViewV2: View {
    @EnvironmentObject private var mailboxManager: MailboxManager

    @State private var showRecipientsFields = false

    @StateRealmObject var draft: Draft

    @FocusState var focusedField: ComposeViewFieldType?

    var body: some View {
        VStack {
            ComposeMessageCellStaticTextV2(type: .from, text: mailboxManager.mailbox.email)
            IKDivider()

            ComposeMessageCellRecipientsV2(
                recipients: $draft.to,
                showRecipientsFields: $showRecipientsFields,
                type: .to
            )

            if showRecipientsFields {
                ComposeMessageCellRecipientsV2(
                    recipients: $draft.cc,
                    showRecipientsFields: $showRecipientsFields,
                    type: .cc
                )

                ComposeMessageCellRecipientsV2(
                    recipients: $draft.bcc,
                    showRecipientsFields: $showRecipientsFields,
                    type: .bcc
                )
            }

            ComposeMessageCellTextFieldV2(text: $draft.subject, type: .subject)
            IKDivider()
        }
        .padding(.horizontal, 16)
        .onAppear {
            showRecipientsFields = !draft.bcc.isEmpty || !draft.cc.isEmpty
        }
    }
}

struct ComposeMessageHeaderViewV2_Previews: PreviewProvider {
    static var previews: some View {
        ComposeMessageHeaderViewV2(draft: Draft())
    }
}
