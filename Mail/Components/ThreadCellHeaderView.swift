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

struct ThreadCellHeaderView: View {
    @EnvironmentObject var mailboxManager: MailboxManager
    let thread: Thread

    var body: some View {
        HStack(spacing: UIPadding.small) {
            if thread.hasDrafts {
                Text("\(MailResourcesStrings.Localizable.draftPrefix)")
                    .textStyle(.bodyMediumError)
                    .lineLimit(1)
                    .layoutPriority(1)
            }
            Text(
                thread,
                format: .recipientNameList(contextMailboxManager: mailboxManager,
                                           style: FolderRole.writtenByMeFolders
                                               .contains { $0 == thread.folder?.role } ? .to : .from)
            )
            .textStyle(.bodyMedium)
            .lineLimit(1)

            if thread.messages.count > 1 {
                ThreadCountIndicatorView(messagesCount: thread.messages.count, hasUnseenMessages: thread.hasUnseenMessages)
                    .accessibilityHidden(true)
            }

            Spacer()

            Text(thread.date.customRelativeFormatted)
                .textStyle(.bodySmallSecondary)
                .lineLimit(1)
                .accessibilityHidden(true)
        }
    }
}
