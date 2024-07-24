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
import RealmSwift
import SwiftUI

struct ComposeMessageBodyView: View {
    @FocusState var focusedField: ComposeViewFieldType?

    @ObservedRealmObject var draft: Draft

    @Binding var isShowingAI: Bool

    let messageReply: MessageReply?

    var body: some View {
        VStack {
            AttachmentsHeaderView()
            ComposeEditor(
                focusedField: _focusedField,
                draft: draft,
                isShowingAI: $isShowingAI,
                messageReply: messageReply
            )
        }
    }
}

#Preview {
    let draft = Draft()
    return ComposeMessageBodyView(
        focusedField: .init(),
        draft: draft,
        isShowingAI: .constant(false),
        messageReply: nil
    )
    .environmentObject(AttachmentsManager(
        draftLocalUUID: draft.localUUID,
        mailboxManager: PreviewHelper.sampleMailboxManager
    ))
}
