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

import Foundation
import MailCore
import SwiftUI

class DraftUtils {
    @MainActor public static func editDraft(from thread: Thread, mailboxManager: MailboxManager, editedMessageDraft: Binding<Draft?>) {
        guard let message = thread.messages.first else { return }
        var sheetPresented = false

        // If we already have the draft locally, present it directly
        if let draft = mailboxManager.draft(messageUid: message.uid)?.detached() {
            editedMessageDraft.wrappedValue = draft
            sheetPresented = true
        } else if let localDraft = mailboxManager.localDraft(uuid: thread.uid)?.detached() {
            editedMessageDraft.wrappedValue = localDraft
            sheetPresented = true
        }

        // Update the draft
        Task { [sheetPresented] in
            let draft = try await mailboxManager.draft(from: message)
            if !sheetPresented {
                editedMessageDraft.wrappedValue = draft
            }
        }
    }
}
