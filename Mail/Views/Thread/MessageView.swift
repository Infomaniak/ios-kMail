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

struct MessageView: View {
    @ObservedObject private var viewModel: MessageViewModel
    @ObservedRealmObject var message: Message

    init(mailboxManager: MailboxManager, message: Message) {
        viewModel = MessageViewModel(mailboxManager: mailboxManager)
        self.message = message
    }

    var body: some View {
        VStack {
            Text(message.subject ?? "No subject")
            Text("Message view")
            Text(message.body?.value ?? "No body")
        }
        .onAppear {
            if self.message.shouldComplete {
                Task {
                    await fetchMessage()
                }
            }
        }
    }

    private func fetchMessage() async {
        do {
            try await viewModel.mailboxManager.message(message: message)
        } catch {
            print("Error while getting folders: \(error.localizedDescription)")
        }
    }
}

struct MessageView_Previews: PreviewProvider {
    static var previews: some View {
        MessageView(
            mailboxManager: MailboxManager(mailbox: PreviewHelper.sampleMailbox, apiFetcher: MailApiFetcher()),
            message: PreviewHelper.sampleMessage
        )
    }
}
