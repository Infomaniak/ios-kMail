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

import InfomaniakCore
import InfomaniakCoreUI
import InfomaniakDI
import MailCore
import MailResources
import RealmSwift
import SwiftUI
import WrappingHStack

struct RecipientField: View {
    @State private var keyboardHeight: CGFloat = 0

    @FocusState var focusedField: ComposeViewFieldType?

    @Binding var currentText: String
    @Binding var recipients: RealmSwift.List<Recipient>

    let type: ComposeViewFieldType
    var onSubmit: (() -> Void)?

    /// A trimmed view on `currentText`
    private var trimmedInputText: String {
        currentText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isCurrentFieldFocused: Bool {
        if case .chip(let hash, _) = focusedField {
            return type.hashValue == hash
        }
        return type == focusedField
    }

    private var isExpanded: Bool {
        return isCurrentFieldFocused || recipients.isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            if !recipients.isEmpty {
                RecipientsList(
                    focusedField: _focusedField,
                    recipients: $recipients,
                    isCurrentFieldFocused: isCurrentFieldFocused,
                    type: type
                )
            }

            RecipientsTextField(text: $currentText, onSubmit: onSubmit, onBackspace: handleBackspaceTextField)
                .focused($focusedField, equals: type)
                .padding(.top, isCurrentFieldFocused && !recipients.isEmpty ? 4 : 0)
                .padding(.top, UIConstants.chipInsets.top)
                .padding(.bottom, UIConstants.chipInsets.bottom)
                .frame(width: isExpanded ? nil : 0, height: isExpanded ? nil : 0)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardDidShowNotification)) { output in
            if let userInfo = output.userInfo,
               let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                keyboardHeight = keyboardFrame.height
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardDidHideNotification)) { _ in
            keyboardHeight = 0
        }
    }

    private func handleBackspaceTextField(isTextEmpty: Bool) {
        if let recipient = recipients.last, isTextEmpty {
            focusedField = .chip(type.hashValue, recipient)
        }
    }
}

struct RecipientField_Previews: PreviewProvider {
    static var previews: some View {
        RecipientField(currentText: .constant(""), recipients: .constant(PreviewHelper.sampleRecipientsList), type: .to)
    }
}
