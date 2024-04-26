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
import MailCoreUI
import RealmSwift
import SwiftUI

struct RecipientsList: View {
    @FocusState var focusedField: ComposeViewFieldType?

    @Binding var recipients: RealmSwift.List<Recipient>

    let isCurrentFieldFocused: Bool
    let type: ComposeViewFieldType

    var body: some View {
        Group {
            if !isCurrentFieldFocused {
                ShortRecipientsList(recipients: recipients, type: type)
                    .transition(.opacity.animation(.spring().speed(2)))
            } else {
                FullRecipientsList(recipients: $recipients, focusedField: _focusedField, type: type)
                    .transition(.opacity.animation(.spring().speed(2)))
            }
        }
        .alignmentGuide(.newMessageCellAlignment) { d in d[.top] + 21 }
    }
}

#Preview {
    RecipientsList(recipients: .constant(PreviewHelper.sampleRecipientsList), isCurrentFieldFocused: true, type: .to)
}
