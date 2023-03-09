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

struct NewMessageCell<Content>: View where Content: View {
    let type: ComposeViewFieldType
    let focusedField: FocusState<ComposeViewFieldType?>?
    let showCc: Binding<Bool>?
    let isFirstCell: Bool
    let content: Content

    let verticalPadding: CGFloat = 12

    init(type: ComposeViewFieldType,
         focusedField: FocusState<ComposeViewFieldType?>? = nil,
         showCc: Binding<Bool>? = nil,
         isFirstCell: Bool = false,
         @ViewBuilder _ content: () -> Content) {
        self.type = type
        self.focusedField = focusedField
        self.showCc = showCc
        self.isFirstCell = isFirstCell
        self.content = content()
    }

    var body: some View {
        HStack(alignment: .newMessageCellAlignment) {
            Text(type.title)
                .textStyle(.bodySecondary)

            content

            Spacer()

            if let showCc = showCc {
                ChevronButton(isExpanded: showCc)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, isFirstCell ? 0 : verticalPadding)
        .padding(.bottom, verticalPadding)
        .onTapGesture {
            focusedField?.wrappedValue = type
        }

        IKDivider()
            .padding(.horizontal, 8)
    }
}

struct RecipientCellView_Previews: PreviewProvider {
    static var previews: some View {
        NewMessageCell(type: .to,
                       showCc: .constant(false)) {
            RecipientField(recipients: .constant([PreviewHelper.sampleRecipient1].toRealmList()),
                           autocompletion: .constant([]),
                           addRecipientHandler: .constant { _ in /* Preview */ },
                           focusedField: .init(),
                           type: .to,
                           matomo: PreviewHelper.sampleMatomo)
        }
        NewMessageCell(type: .subject) {
            TextField("", text: .constant(""))
        }
    }
}
