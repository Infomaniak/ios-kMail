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

import MailCore
import MailCoreUI
import MailResources
import RealmSwift
import SwiftUI

struct ComposeMessageHeaderView: View {
    @EnvironmentObject private var mailboxManager: MailboxManager

    @State private var showRecipientsFields = false

    @ObservedRealmObject var draft: Draft

    @FocusState var focusedField: ComposeViewFieldType?

    @Binding var autocompletionType: ComposeViewFieldType?
    @Binding var currentSignature: Signature?

    var body: some View {
        VStack(spacing: 0) {
            ComposeMessageSenderMenu(
                currentSignature: $currentSignature,
                mailboxManager: mailboxManager,
                autocompletionType: autocompletionType,
                type: .from
            )

            ComposeMessageCellRecipients(
                recipients: $draft.to,
                showRecipientsFields: $showRecipientsFields,
                autocompletionType: $autocompletionType,
                focusedField: _focusedField,
                type: .to,
                areCCAndBCCEmpty: draft.cc.isEmpty && draft.bcc.isEmpty
            )
            .accessibilityLabel(MailResourcesStrings.Localizable.toTitle)

            if showRecipientsFields {
                ComposeMessageCellRecipients(
                    recipients: $draft.cc,
                    showRecipientsFields: $showRecipientsFields,
                    autocompletionType: $autocompletionType,
                    focusedField: _focusedField,
                    type: .cc
                )
                .accessibilityLabel(MailResourcesStrings.Localizable.ccTitle)

                ComposeMessageCellRecipients(
                    recipients: $draft.bcc,
                    showRecipientsFields: $showRecipientsFields,
                    autocompletionType: $autocompletionType,
                    focusedField: _focusedField,
                    type: .bcc
                )
                .accessibilityLabel(MailResourcesStrings.Localizable.bccTitle)
            }

            ComposeMessageCellTextField(
                text: $draft.subject,
                focusedField: _focusedField,
                autocompletionType: autocompletionType,
                type: .subject
            )
            .accessibilityLabel(MailResourcesStrings.Localizable.subjectTitle)
        }
        .onAppear {
            showRecipientsFields = !draft.bcc.isEmpty || !draft.cc.isEmpty
        }
    }
}

#Preview {
    ComposeMessageHeaderView(draft: Draft(), autocompletionType: .constant(nil), currentSignature: .constant(nil))
        .environmentObject(PreviewHelper.sampleMailboxManager)
}
