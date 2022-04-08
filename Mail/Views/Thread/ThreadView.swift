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

struct ThreadView: View {
    @ObservedRealmObject var thread: Thread
    private var mailboxManager: MailboxManager

    init(mailboxManager: MailboxManager, thread: Thread) {
        self.mailboxManager = mailboxManager
        self.thread = thread
    }

    var body: some View {
        ScrollView {
            VStack {
                Text(thread.subject ?? "")
                    .font(.largeTitle)
                ForEach(thread.messages) { message in
                    MessageView(mailboxManager: mailboxManager, message: message)
                }
            }
        }
        .padding(8)
        .onAppear {
            MatomoUtils.track(view: ["MessageView"])
        }
    }
}

struct ThreadView_Previews: PreviewProvider {
    static var previews: some View {
        ThreadView(
            mailboxManager: MailboxManager(mailbox: PreviewHelper.sampleMailbox, apiFetcher: MailApiFetcher()),
            thread: PreviewHelper.sampleThread
        )
    }
}
