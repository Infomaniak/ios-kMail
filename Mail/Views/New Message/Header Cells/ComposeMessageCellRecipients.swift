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

import InfomaniakCoreUI
import InfomaniakDI
import MailCore
import MailCoreUI
import MailResources
import RealmSwift
import SwiftUI

extension VerticalAlignment {
    struct NewMessageCellAlignment: AlignmentID {
        static func defaultValue(in context: ViewDimensions) -> CGFloat {
            context[.firstTextBaseline]
        }
    }

    static let newMessageCellAlignment = VerticalAlignment(NewMessageCellAlignment.self)
}

class TextDebounce: ObservableObject {
    @Published var text = ""
}

struct ComposeMessageCellRecipients: View {
    @StateObject private var textDebounce = TextDebounce()

    @State private var autocompletion = [Recipient]()

    @Binding var recipients: RealmSwift.List<Recipient>
    @Binding var showRecipientsFields: Bool
    @Binding var autocompletionType: ComposeViewFieldType?

    @FocusState var focusedField: ComposeViewFieldType?

    @LazyInjectService private var snackbarPresenter: SnackBarPresentable
    @LazyInjectService private var matomo: MatomoUtils

    let type: ComposeViewFieldType
    var areCCAndBCCEmpty = false

    /// It should be displayed only for the field to if cc and bcc are empty and when autocompletion is not displayed
    private var shouldDisplayChevron: Bool {
        return type == .to && autocompletionType == nil && areCCAndBCCEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            if autocompletionType == nil || autocompletionType == type {
                HStack {
                    HStack(alignment: .newMessageCellAlignment) {
                        Text(type.title)
                            .textStyle(.bodySecondary)

                        RecipientField(
                            focusedField: _focusedField,
                            currentText: $textDebounce.text,
                            recipients: $recipients,
                            type: type
                        ) {
                            if let bestMatch = autocompletion.first {
                                addNewRecipient(bestMatch)
                            }
                        }
                    }
                    .padding(.vertical, value: .intermediate)

                    if shouldDisplayChevron {
                        Spacer()
                        ChevronButton(isExpanded: $showRecipientsFields)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, UIPadding.composeViewHeaderHorizontal)

                IKDivider()
            }

            if autocompletionType == type {
                AutocompletionView(
                    textDebounce: textDebounce,
                    autocompletion: $autocompletion,
                    addedRecipients: $recipients,
                    addRecipient: addNewRecipient
                )
                .padding(.top, value: .small)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            focusedField = type
        }
        .onChange(of: textDebounce.text) { newValue in
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
        matomo.track(eventWithCategory: .newMessage, name: "addNewRecipient")

        guard Constants.isEmailAddress(recipient.email) else {
            snackbarPresenter.show(message: MailResourcesStrings.Localizable.addUnknownRecipientInvalidEmail)
            return
        }

        guard !recipients.contains(where: { $0.isSameCorrespondent(as: recipient) }) else {
            snackbarPresenter.show(message: MailResourcesStrings.Localizable.addUnknownRecipientAlreadyUsed)
            return
        }

        withAnimation {
            recipient.isAddedByMe = true
            $recipients.append(recipient)
        }
        textDebounce.text = ""
    }
}

#Preview {
    ComposeMessageCellRecipients(
        recipients: .constant(PreviewHelper.sampleRecipientsList),
        showRecipientsFields: .constant(false),
        autocompletionType: .constant(nil),
        type: .bcc
    )
    .environmentObject(PreviewHelper.sampleMailboxManager)
}
