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

import InfomaniakCore
import MailCore
import MailResources
import SwiftModalPresentation
import SwiftUI
import MailCoreUI

struct AccountButton: View {
    @EnvironmentObject private var mailboxManager: MailboxManager

    @ModalState private var presentedCurrentAccount: Account?

    var body: some View {
        Button {
            presentedCurrentAccount = mailboxManager.account
        } label: {
            if let currentAccountUser = mailboxManager.account.user {
                AvatarView(mailboxManager: mailboxManager,
                           contactConfiguration: .user(user: currentAccountUser))
            }
        }
        .sheet(item: $presentedCurrentAccount) { account in
            AccountView(account: account)
        }
    }
}

#Preview {
    AccountButton()
        .environmentObject(PreviewHelper.sampleMailboxManager)
}
