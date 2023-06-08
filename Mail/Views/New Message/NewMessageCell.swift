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
import RealmSwift
import SwiftUI

extension VerticalAlignment {
    private struct NewMessageCellAlignment: AlignmentID {
        static func defaultValue(in context: ViewDimensions) -> CGFloat {
            context[.firstTextBaseline]
        }
    }

    static let newMessageCellAlignment = VerticalAlignment(NewMessageCellAlignment.self)
}

struct NewMessageCell<Content: View>: View {
    @FocusState var focusedField: ComposeViewFieldType?

    @Binding var showCc: Bool

    let type: ComposeViewFieldType
    var isFirstCell = false

    @ViewBuilder var content: Content

    var body: some View {
        HStack(alignment: .newMessageCellAlignment) {
            Text(type.title)
                .textStyle(.bodySecondary)

            content
                .frame(maxWidth: .infinity, alignment: .leading)

            if type == .to {
                ChevronButton(isExpanded: $showCc)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, isFirstCell ? 0 : UIConstants.newMessageCellVerticalPadding)
        .padding(.bottom, UIConstants.newMessageCellVerticalPadding)
        .onTapGesture {
            focusedField = type
        }

        IKDivider()
            .padding(.horizontal, 8)
    }
}

struct NewMessageCell_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            NewMessageCell(showCc: .constant(false), type: .to) {
                RecipientField(recipients: .constant([PreviewHelper.sampleRecipient1].toRealmList()),
                               autocompletion: .constant([]),
                               unknownRecipientAutocompletion: .constant(""),
                               addRecipientHandler: .constant { _ in /* Preview */ },
                               focusedField: .init(),
                               type: .to)
            }

            NewMessageCell(showCc: .constant(false), type: .subject) {
                TextField("", text: .constant(""))
            }
        }
    }
}
