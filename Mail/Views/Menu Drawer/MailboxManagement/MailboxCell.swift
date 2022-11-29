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
import MailResources
import SwiftUI

struct MailboxCell: View {
    let mailbox: Mailbox

    @Environment(\.window) private var window

    var body: some View {
        MailboxesManagementButtonView(icon: MailResourcesAsset.envelope, text: mailbox.email, detailNumber: mailbox.unseenMessages > 0 ? mailbox.unseenMessages : nil) {
            (window?.windowScene?.delegate as? SceneDelegate)?.switchMailbox(mailbox)
        }
    }
}

struct MailboxCell_Previews: PreviewProvider {
    static var previews: some View {
        MailboxCell(mailbox: PreviewHelper.sampleMailbox)
    }
}
