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
    @EnvironmentObject var splitViewManager: SplitViewManager
    @EnvironmentObject var mailboxManager: MailboxManager

    @State private var shouldNavigateToNotificationThread = false
    @State private var tappedNotificationThread: Thread?
    @State private var editedMessageDraft: Draft?
    @State private var messageReply: MessageReply?

    let isCompact: Bool

    var body: some View {
        ZStack {
            NavigationLink(isActive: $shouldNavigateToNotificationThread) {
                if let tappedNotificationThread {
                    ThreadView(mailboxManager: mailboxManager,
                               thread: tappedNotificationThread)
                }
            } label: {
                EmptyView()
            }
            .opacity(0)
            if let selectedFolder = splitViewManager.selectedFolder {
                if splitViewManager.showSearch {
                    SearchView(
                        mailboxManager: mailboxManager,
                        folder: selectedFolder,
                        editedMessageDraft: $editedMessageDraft,
                        messageReply: $messageReply,
                        isCompact: isCompact
                    )
                } else {
                    ThreadListView(
                        mailboxManager: mailboxManager,
                        folder: selectedFolder,
                        editedMessageDraft: $editedMessageDraft,
                        messageReply: $messageReply,
                        isCompact: isCompact
                    )
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .onUserTappedNotification)) { notification in
            guard let notificationPayload = notification.object as? NotificationTappedPayload else { return }
            let realm = mailboxManager.getRealm()
            realm.refresh()

            let tappedNotificationMessage = realm.object(ofType: Message.self, forPrimaryKey: notificationPayload.messageId)
            // Original parent should always be in the inbox but maybe change in a later stage to always find the parent in inbox
            if let tappedNotificationThread = tappedNotificationMessage?.originalThread {
                self.tappedNotificationThread = tappedNotificationThread
                shouldNavigateToNotificationThread = true
            } else {
                IKSnackBar.showSnackBar(message: MailError.messageNotFound.errorDescription ?? "")
            }
        }
        .animation(.easeInOut(duration: 0.25), value: splitViewManager.showSearch)
        .sheet(item: $editedMessageDraft) { draft in
            ComposeMessageView.editDraft(draft: draft, mailboxManager: mailboxManager)
        }
        .sheet(item: $messageReply) { messageReply in
            ComposeMessageView.replyOrForwardMessage(messageReply: messageReply, mailboxManager: mailboxManager)
        }
    }
}

struct ThreadListManagerView_Previews: PreviewProvider {
    static var previews: some View {
        ThreadListManagerView(
            isCompact: false
        )
        .environmentObject(PreviewHelper.sampleMailboxManager)
    }
}
