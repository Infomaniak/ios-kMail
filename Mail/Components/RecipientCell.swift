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

struct RecipientCell: View {
    let recipient: Recipient

    var body: some View {
        HStack(spacing: 8) {
            AvatarView(avatarDisplayable: recipient, size: 40)
                .accessibilityHidden(true)

            if recipient.name.isEmpty {
                Text(recipient.email)
                    .textStyle(.bodyMedium)
            } else {
                VStack(alignment: .leading) {
                    Text(recipient.name)
                        .textStyle(.bodyMedium)
                    Text(recipient.email)
                        .textStyle(.bodySecondary)
                }
            }
        }
        .lineLimit(1)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }
}

struct RecipientAutocompletionCell_Previews: PreviewProvider {
    static var previews: some View {
        RecipientCell(recipient: PreviewHelper.sampleRecipient1)
        RecipientCell(recipient: PreviewHelper.sampleRecipient3)
    }
}
