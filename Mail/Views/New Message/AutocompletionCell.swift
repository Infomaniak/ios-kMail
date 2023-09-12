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

struct AutocompletionCell: View {
    let addRecipient: @MainActor (Recipient) -> Void
    let recipient: Recipient
    var highlight: String?
    let alreadyAppend: Bool
    let unknownRecipient: Bool

    var body: some View {
        HStack(spacing: UIPadding.intermediate) {
            Button {
                addRecipient(recipient)
            } label: {
                if unknownRecipient {
                    UnknownRecipientCell(recipient: recipient)
                } else {
                    RecipientCell(recipient: recipient, highlight: highlight)
                }
            }
            .allowsHitTesting(!alreadyAppend || unknownRecipient)
            .opacity(alreadyAppend && !unknownRecipient ? 0.5 : 1)

            if alreadyAppend && !unknownRecipient {
                MailResourcesAsset.checked.swiftUIImage
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundColor(MailResourcesAsset.textTertiaryColor.swiftUIColor)
            }
        }
        .padding(.horizontal, value: .regular)
    }
}

struct AutocompletionCell_Previews: PreviewProvider {
    static var previews: some View {
        AutocompletionCell(
            addRecipient: { _ in /* Preview */ },
            recipient: PreviewHelper.sampleRecipient1,
            alreadyAppend: false,
            unknownRecipient: false
        )
    }
}
