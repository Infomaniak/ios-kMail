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
import InfomaniakCoreSwiftUI
import MailCore
import MailCoreUI
import MailResources
import SwiftUI

struct AutocompletionCell: View {
    let addRecipient: @MainActor (any ContactAutocompletable) -> Void
    let autocompletion: any ContactAutocompletable
    var highlight: String?
    let alreadyAppend: Bool
    let unknownRecipient: Bool

    var body: some View {
        HStack(spacing: IKPadding.small) {
            Button {
                addRecipient(autocompletion)
            } label: {
                if unknownRecipient, let email = autocompletion.email {
                    UnknownRecipientCell(email: email)
                } else {
                    RecipientCell(contact: autocompletion, highlight: highlight)
                }
            }
            .allowsHitTesting(!alreadyAppend || unknownRecipient)
            .opacity(alreadyAppend && !unknownRecipient ? 0.5 : 1)

            if alreadyAppend && !unknownRecipient {
                MailResourcesAsset.checkmarkCircleFill
                    .iconSize(.large)
                    .foregroundStyle(MailResourcesAsset.textTertiaryColor)
            }
        }
        .padding(.horizontal, value: .medium)
    }
}

#Preview {
    AutocompletionCell(
        addRecipient: { _ in /* Preview */ },
        autocompletion: PreviewHelper.sampleMergedContact,
        alreadyAppend: false,
        unknownRecipient: false
    )
    .environmentObject(PreviewHelper.sampleMailboxManager)
}
