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
import SwiftUI

struct AccountListMailView: View {
    let mailbox: Mailbox

    private var isSelected: Bool {
        return mailbox.userId == AccountManager.instance.currentUserId
            && mailbox.mailboxId == AccountManager.instance.currentMailboxId
    }

    var body: some View {
        HStack(spacing: 16) {
            Image(resource: MailResourcesAsset.envelope)
                .resizable()
                .frame(width: 24, height: 24)

            Text(mailbox.email)
                .lineLimit(1)

            Spacer()

            if mailbox.unseenMessages > 0 {
                Text(mailbox.unseenMessages < 100 ? "\(mailbox.unseenMessages)" : "99+")
                    .foregroundColor(.accentColor)
            }
        }
        .foregroundColor(isSelected ? Color.accentColor : MailResourcesAsset.primaryTextColor.swiftUiColor)
        .textStyle(isSelected ? .calloutStrong : .callout)
        .onAppear {
            // TODO: Get unread count
        }
    }
}

struct AccountListMailView_Previews: PreviewProvider {
    static var previews: some View {
        AccountListMailView(mailbox: PreviewHelper.sampleMailbox)
    }
}
