/*
 Infomaniak Mail - iOS App
 Copyright (C) 2024 Infomaniak Network SA

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

import InfomaniakCore
import InfomaniakDI
import MailCore
import MailCoreUI
import MailResources
import SwiftModalPresentation
import SwiftUI

struct AccountButton: View {
    @LazyInjectService private var accountManager: AccountManager

    @Environment(\.currentUser) private var currentUser

    @EnvironmentObject private var mailboxManager: MailboxManager

    @State private var isShowingNewAccountListView = false

    var body: some View {
        Button {
            isShowingNewAccountListView = true
        } label: {
            AvatarView(mailboxManager: mailboxManager,
                       contactConfiguration: .user(user: currentUser.value))
                .accessibilityLabel(MailResourcesStrings.Localizable.titleMyAccount(1))
        }
        .floatingPanel(
            isPresented: $isShowingNewAccountListView,
            title: MailResourcesStrings.Localizable.titleMyAccount(accountManager.accounts.count)
        ) {
            AccountListView(mailboxManager: mailboxManager)
        }
    }
}

#Preview {
    AccountButton()
        .environmentObject(PreviewHelper.sampleMailboxManager)
}
