/*
 Infomaniak Mail - iOS App
 Copyright (C) 2022 Infomaniak Network SA

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

import InfomaniakDI
import MailCore
import RealmSwift
import SwiftUI

struct ForEachMailboxView<Content: View>: View {
    @ObservedResults private var mailboxes: Results<Mailbox>

    var sortedMailboxes: [Mailbox] {
        let sorted = Array(mailboxes).webmailSorted()
        return sorted
    }

    let content: (Mailbox) -> Content

    init(userId: Int, excludedMailboxIds: [Int] = [], @ViewBuilder content: @escaping (Mailbox) -> Content) {
        self.content = content
        let configuration = {
            @InjectService var mailboxInfosManager: MailboxInfosManager
            return mailboxInfosManager.realmConfiguration
        }()
        _mailboxes = ObservedResults(Mailbox.self, configuration: configuration) {
            $0.userId == userId && !$0.mailboxId.in(excludedMailboxIds)
        }
    }

    var body: some View {
        ForEach(sortedMailboxes) { mailbox in
            content(mailbox)
        }
    }
}
