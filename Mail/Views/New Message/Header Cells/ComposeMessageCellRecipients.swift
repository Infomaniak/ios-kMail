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

import InfomaniakCoreUI
import InfomaniakDI
import MailCore
import MailResources
import RealmSwift
import SwiftUI

struct ComposeMessageCellRecipients: View {
    @State private var currentText = ""
    @State private var autocompletion = [Recipient]()

    @Binding var recipients: RealmSwift.List<Recipient>
    @Binding var showRecipientsFields: Bool
    @Binding var autocompletionType: ComposeViewFieldType?

    @FocusState var focusedField: ComposeViewFieldType?

    let type: ComposeViewFieldType

    var body: some View {
        VStack(spacing: 0) {
            if autocompletionType == nil || autocompletionType == type {
                HStack {
                    Text(type.title)
                        .textStyle(.bodySecondary)

                    RecipientField(currentText: $currentText, recipients: $recipients, focusedField: _focusedField, type: type) {
                        if let bestMatch = autocompletion.first {
                            addNewRecipient(bestMatch)
                        }
                    }

                    if type == .to && autocompletionType == nil {
                        Spacer()
                        ChevronButton(isExpanded: $showRecipientsFields)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                IKDivider()
                    .padding(.top, UIConstants.composeViewVerticalSpacing)
            }

            if autocompletionType == type {
                AutocompletionView(
                    autocompletion: $autocompletion,
                    currentSearch: $currentText,
                    addedRecipients: $recipients,
                    addRecipient: addNewRecipient
                )
                .padding(.top, 8)
            }
        }
        .onTapGesture {
            focusedField = type
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

    @MainActor private func addNewRecipient(_ recipient: Recipient) {
        @InjectService var matomo: MatomoUtils
        matomo.track(eventWithCategory: .newMessage, name: "addNewRecipient")

        guard Constants.isEmailAddress(recipient.email) else {
            IKSnackBar.showSnackBar(message: MailResourcesStrings.Localizable.addUnknownRecipientInvalidEmail)
            return
        }

        guard !recipients.contains(where: { $0.isSameRecipient(as: recipient) }) else {
            IKSnackBar.showSnackBar(message: MailResourcesStrings.Localizable.addUnknownRecipientAlreadyUsed)
            return
        }

        withAnimation {
            $recipients.append(recipient)
        }
        currentText = ""
    }
}

struct ComposeMessageCellRecipients_Previews: PreviewProvider {
    static var previews: some View {
        ComposeMessageCellRecipients(recipients: .constant([
            PreviewHelper.sampleRecipient1, PreviewHelper.sampleRecipient2, PreviewHelper.sampleRecipient3
        ].toRealmList()), showRecipientsFields: .constant(false), autocompletionType: .constant(nil), type: .bcc)
    }
}
