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

import InfomaniakCoreUI
import MailCore
import MailResources
import SwiftUI

struct ThreadListManagerView: View {
    @Environment(\.isCompactWindow) private var isCompactWindow

    @EnvironmentObject private var splitViewManager: SplitViewManager
    @EnvironmentObject private var mailboxManager: MailboxManager

    @State private var shouldNavigateToNotificationThread = false
    @State private var tappedNotificationThread: Thread?
    @State private var editedMessageDraft: Draft?
    @State private var messageReply: MessageReply?

    var body: some View {
        Group {
            if let selectedFolder = splitViewManager.selectedFolder {
                if splitViewManager.showSearch {
                    SearchView(
                        mailboxManager: mailboxManager,
                        folder: selectedFolder,
                        editedMessageDraft: $editedMessageDraft
                    )
                } else {
                    ThreadListView(
                        mailboxManager: mailboxManager,
                        folder: selectedFolder,
                        editedMessageDraft: $editedMessageDraft,
                        messageReply: $messageReply,
                        isCompact: isCompactWindow
                    )
                }
            }
        }
        .id(mailboxManager.mailbox.id)
        .animation(.easeInOut(duration: 0.25), value: splitViewManager.showSearch)
        .sheet(item: $editedMessageDraft) { draft in
            ComposeMessageView.edit(draft: draft, mailboxManager: mailboxManager)
        }
    }
}

struct ThreadListManagerView_Previews: PreviewProvider {
    static var previews: some View {
        ThreadListManagerView()
        .environmentObject(PreviewHelper.sampleMailboxManager)
    }
}
