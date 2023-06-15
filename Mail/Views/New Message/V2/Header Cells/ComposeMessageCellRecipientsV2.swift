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
import RealmSwift
import SwiftUI

struct ComposeMessageCellRecipientsV2: View {
    @State private var currentText = ""

    @Binding var recipients: RealmSwift.List<Recipient>
    @Binding var showRecipientsFields: Bool
    @Binding var autocompletionType: ComposeViewFieldType?

    let type: ComposeViewFieldType

    var body: some View {
        VStack {
            if autocompletionType == nil || autocompletionType == type {
                HStack {
                    Text(type.title)
                        .textStyle(.bodySecondary)

                    RecipientFieldV2(currentText: $currentText, recipients: $recipients, type: type)

                    if type == .to && autocompletionType == nil {
                        Spacer()
                        ChevronButton(isExpanded: $showRecipientsFields)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                IKDivider()
            }

            // TODO: Add autocomplete
        }
        .onChange(of: currentText) { newValue in
            withAnimation {
                if newValue.isEmpty {
                    autocompletionType = nil
                } else {
                    autocompletionType = type
                }
            }
        }
    }
}

struct ComposeMessageCellRecipientsV2_Previews: PreviewProvider {
    static var previews: some View {
        ComposeMessageCellRecipientsV2(recipients: .constant([
            PreviewHelper.sampleRecipient1, PreviewHelper.sampleRecipient2, PreviewHelper.sampleRecipient3
        ].toRealmList()), showRecipientsFields: .constant(false), autocompletionType: .constant(nil), type: .bcc)
    }
}
