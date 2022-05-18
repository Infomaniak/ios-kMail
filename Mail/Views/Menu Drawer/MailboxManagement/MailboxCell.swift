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

struct MailboxCell: View {
    @State var mailbox: Mailbox
    @State var unreadMessages = false

    var body: some View {
        MailboxesManagementButtonView(text: mailbox.email, showBadge: $unreadMessages) {
            // TODO: Switch mailbox
            AccountManager.instance.setCurrentMailboxForCurrentAccount(mailbox: mailbox)
            AccountManager.instance.saveAccounts()
            (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.setRootViewController(UIHostingController(rootView: SplitView()))
        }
        .onAppear {
            hasUnreadMessages()
        }
    }

    private func hasUnreadMessages() {
        guard let mailboxManager = AccountManager.instance.getMailboxManager(for: mailbox) else { return }
        unreadMessages = mailboxManager.hasUnreadMessages()
    }
}

struct MailboxCell_Previews: PreviewProvider {
    static var previews: some View {
        MailboxCell(mailbox: PreviewHelper.sampleMailbox)
    }
}
