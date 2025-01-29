/*
 Infomaniak Mail - iOS App
 Copyright (C) 2023 Infomaniak Network SA

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
import InfomaniakCoreSwiftUI
import MailCore
import MailResources
import SwiftUI

struct ThreadCellHeaderView: View, Equatable {
    let recipientsTitle: String
    let messageCount: Int
    let prominentMessageCount: Bool
    let formattedDate: String
    let showDraftPrefix: Bool

    var body: some View {
        HStack(spacing: IKPadding.mini) {
            HStack(spacing: IKPadding.mini) {
                if showDraftPrefix {
                    Text("\(MailResourcesStrings.Localizable.draftPrefix)")
                        .textStyle(.bodyMediumError)
                        .lineLimit(1)
                        .layoutPriority(1)
                }

                Text(recipientsTitle)
                    .textStyle(.bodyMedium)
                    .lineLimit(1)

                if messageCount > 1 {
                    ThreadCountIndicatorView(messagesCount: messageCount, hasUnseenMessages: prominentMessageCount)
                        .accessibilityHidden(true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(formattedDate)
                .textStyle(.bodySmallSecondary)
                .lineLimit(1)
                .layoutPriority(1)
                .accessibilityHidden(true)
        }
    }
}
