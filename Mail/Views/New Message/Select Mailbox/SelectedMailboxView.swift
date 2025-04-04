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

import DesignSystem
import InfomaniakCore
import InfomaniakCoreSwiftUI
import MailCore
import MailCoreUI
import MailResources
import SwiftUI

struct SelectedMailboxView: View {
    let selectedUser: UserProfile
    let selectedMailboxManager: MailboxManager

    var body: some View {
        HStack(spacing: IKPadding.mini) {
            AvatarView(
                mailboxManager: selectedMailboxManager,
                contactConfiguration: .user(user: selectedUser),
                size: 40
            )
            Text(selectedMailboxManager.mailbox.email)
                .textStyle(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
            MailResourcesAsset.checkmarkCircleFill.swiftUIImage
                .foregroundStyle(MailResourcesAsset.greenColor)
        }
        .lineLimit(1)
        .padding(.vertical, value: .mini)
        .padding(.horizontal, value: .medium)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(MailResourcesAsset.textFieldColor.swiftUIColor)
        )
    }
}

#Preview {
    SelectedMailboxView(
        selectedUser: PreviewHelper.sampleUser,
        selectedMailboxManager: PreviewHelper.sampleMailboxManager
    )
}
