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
import SwiftUI

struct ThreadListManagerView: View {
    @EnvironmentObject var splitViewManager: SplitViewManager
    @State private var editedMessageDraft: Draft?

    var mailboxManager: MailboxManager

    let isCompact: Bool

    var body: some View {
        ZStack {
            if splitViewManager.showSearch {
                SearchView(
                    mailboxManager: mailboxManager,
                    folder: splitViewManager.selectedFolder,
                    editedMessageDraft: $editedMessageDraft,
                    isCompact: isCompact
                )
            } else {
                ThreadListView(
                    mailboxManager: mailboxManager,
                    folder: splitViewManager.selectedFolder,
                    editedMessageDraft: $editedMessageDraft,
                    isCompact: isCompact
                )
            }
        }
        .animation(.easeInOut(duration: 0.25), value: splitViewManager.showSearch)
        .sheet(item: $editedMessageDraft) { draft in
            NewMessageView(mailboxManager: mailboxManager, draft: draft.asUnmanaged())
        }
    }
}

struct ThreadListManagerView_Previews: PreviewProvider {
    static var previews: some View {
        ThreadListManagerView(
            mailboxManager: PreviewHelper.sampleMailboxManager,
            isCompact: false
        )
    }
}
