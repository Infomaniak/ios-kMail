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

struct ComposeMessageCellStaticText: View {
    @Binding var autocompletionType: ComposeViewFieldType?

    let type: ComposeViewFieldType
    let text: String

    var body: some View {
        if autocompletionType == nil {
            VStack(spacing: 0) {
                HStack {
                    Text(type.title)
                        .textStyle(.bodySecondary)

                    Text(text)
                        .textStyle(.body)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, UIConstants.composeViewHeaderCellLargeVerticalSpacing)
                
                IKDivider()
            }
        }
    }
}

struct ComposeMessageStaticText_Previews: PreviewProvider {
    static var previews: some View {
        ComposeMessageCellStaticText(autocompletionType: .constant(nil), type: .from, text: "myaddress@email.com")
    }
}
