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

struct AutocompletionView: View {
    @Binding var autocompletion: [Recipient]
    @Binding var unknownRecipientAutocompletion: String

    let onSelect: (Recipient) -> Void

    var body: some View {
        LazyVStack {
            ForEach(autocompletion) { recipient in
                VStack(alignment: .leading, spacing: 8) {
                    Button {
                        onSelect(recipient)
                    } label: {
                        RecipientCell(recipient: recipient)
                    }
                    .padding(.horizontal, 8)

                    IKDivider()
                }
            }

            if !unknownRecipientAutocompletion.isEmpty {
                Button {
                    onSelect(Recipient(email: unknownRecipientAutocompletion, name: ""))
                } label: {
                    AddRecipientCell(recipientEmail: unknownRecipientAutocompletion)
                }
                .padding(.horizontal, 8)
            }
        }
        .padding(.top, 8)
        .padding(.horizontal, 8)
    }
}

struct AutocompletionView_Previews: PreviewProvider {
    static var previews: some View {
        AutocompletionView(autocompletion: .constant([
            PreviewHelper.sampleRecipient1, PreviewHelper.sampleRecipient2, PreviewHelper.sampleRecipient3
        ]),
        unknownRecipientAutocompletion: .constant("")) { _ in /* Preview */ }
    }
}
