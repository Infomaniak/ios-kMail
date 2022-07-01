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

struct NewMessageCell<Content>: View where Content: View {
    let title: String
    let showCc: Binding<Bool>?
    let content: Content

    init(title: String, showCc: Binding<Bool>? = nil, @ViewBuilder _ content: () -> Content) {
        self.title = title
        self.showCc = showCc
        self.content = content()
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .textStyle(.bodySecondary)

            content

            if let showCc = showCc {
                ChevronButton(isExpanded: showCc)
            }
        }
        .textStyle(.body)
        .padding([.leading, .trailing], 16)

        IKDivider()
            .padding([.leading, .trailing], 8)
    }
}

struct RecipientCellView_Previews: PreviewProvider {
    static var previews: some View {
        NewMessageCell(title: "To:", showCc: .constant(false)) {
            RecipientField(recipients: .constant([PreviewHelper.sampleRecipient1]),
                           autocompletion: .constant([]),
                           addRecipientHandler: .constant { _ in },
                           focusedField: .init(),
                           type: .to)
        }
        NewMessageCell(title: "Subject:") {
            TextField("", text: .constant(""))
        }
    }
}
