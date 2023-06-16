//
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

import SwiftUI
import MailCore

struct AutocompletionCell: View {
    let addRecipient: @MainActor (Recipient) -> Void
    let recipient: Recipient
    var highlight: String?
    let alreadyAppend: Bool
    
    var body: some View {
        HStack {
            Button {
                addRecipient(recipient)
            } label: {
                RecipientCell(recipient: recipient, highlight: highlight)
            }
            .disabled(alreadyAppend)

            if alreadyAppend {
                Text("v") // TODO: Realm image
            }
        }
        .padding(.horizontal, 8)
    }
}

struct AutocompletionCell_Previews: PreviewProvider {
    static var previews: some View {
        AutocompletionCell(addRecipient: { _ in /* Preview */}, recipient: PreviewHelper.sampleRecipient1, alreadyAppend: false)
    }
}
