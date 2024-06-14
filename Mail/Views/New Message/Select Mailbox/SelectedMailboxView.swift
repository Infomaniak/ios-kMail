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
import MailCore
import MailCoreUI
import MailResources
import SwiftUI

struct SelectedMailboxView: View {
    @EnvironmentObject private var mailboxManager: MailboxManager

    let account: Account
    let selectedMailbox: Mailbox

    var body: some View {
        HStack(spacing: UIPadding.small) {
            AvatarView(mailboxManager: mailboxManager, contactConfiguration: .user(user: account.user), size: 40)
            Text(selectedMailbox.email)
                .textStyle(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
            MailResourcesAsset.checkmarkCircleFill.swiftUIImage
                .foregroundStyle(MailResourcesAsset.greenColor)
        }
        .lineLimit(1)
        .padding(.vertical, value: .small)
        .padding(.horizontal, value: .regular)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(MailResourcesAsset.textFieldColor.swiftUIColor)
        )
    }
}

#Preview {
    SelectedMailboxView(account: PreviewHelper.sampleAccount, selectedMailbox: PreviewHelper.sampleMailbox)
}
