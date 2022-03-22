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
import RealmSwift
import SwiftUI

@MainActor class MessageViewModel: ObservableObject {
    var mailboxManager: MailboxManager
    @ObservedRealmObject var message: Message

    init(mailboxManager: MailboxManager, message: Message) {
        self.mailboxManager = mailboxManager
//        self.message = mailboxManager.getRealm().object(ofType: Message.self, forPrimaryKey: message.uid)!

        _message = .init(wrappedValue: mailboxManager.getRealm().object(ofType: Message.self, forPrimaryKey: message.uid)!)

//        if let cachedMessage = mailboxManager.getRealm().object(ofType: Message.self, forPrimaryKey: message.uid) {
//            self.message = cachedMessage
//            if cachedMessage.shouldComplete {
        if self.message.shouldComplete {
            Task {
                print(self.message.body?.value)
                await fetchMessage()
                print(self.message.body?.value)
            }
        }
//        }
    }

    func fetchMessage() async {
        do {
            try await mailboxManager.message(message: message)
        } catch {
            print("Error while getting folders: \(error.localizedDescription)")
        }
    }
}
