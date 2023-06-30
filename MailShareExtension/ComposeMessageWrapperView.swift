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
import InfomaniakDI
import MailCore
import Social
import SwiftUI
import UIKit

struct ComposeMessageWrapperView: View {
    @State var completionHandler: () -> Void
    @State var itemProviders: [NSItemProvider]
    @State private var draft = Draft()
    @LazyInjectService private var accountManager: AccountManager

    var body: some View {
        if let mailboxManager = accountManager.currentMailboxManager {
            ComposeMessageView.newMessage(draft, mailboxManager: mailboxManager, itemProviders: itemProviders)
                .environmentObject(mailboxManager)
                .environment(\.dismissModal) {
                    self.completionHandler()
                }
        } else {
            Text("Please login in ikMail")
                .background(.red)
        }
    }
}
