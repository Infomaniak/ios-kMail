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
import SwiftUI

struct ComposeMessageCellTextField: View {
    @Binding var text: String

    @FocusState var focusedField: ComposeViewFieldType?

    let autocompletionType: ComposeViewFieldType?
    let type: ComposeViewFieldType

    var body: some View {
        if autocompletionType == nil {
            VStack(spacing: 0) {
                HStack(alignment: .top, spacing: IKPadding.mini) {
                    Text(type.title)
                        .textStyle(.bodySecondary)

                    TextField("", text: $text, axis: .vertical)
                        .focused($focusedField, equals: .subject)
                        .textStyle(.body)
                        .accessibilityIdentifier(type.title)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, IKPadding.composeViewHeaderCellLargeVertical)
                .padding(.horizontal, IKPadding.composeViewHeaderHorizontal)

                IKDivider()
            }
            .onTapGesture {
                focusedField = type
            }
        }
    }
}

#Preview {
    ComposeMessageCellTextField(text: .constant(""), autocompletionType: nil, type: .subject)
}
