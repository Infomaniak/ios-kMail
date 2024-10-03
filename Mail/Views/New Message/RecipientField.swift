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

import InfomaniakCore
import InfomaniakCoreSwiftUI
import InfomaniakDI
import MailCore
import MailCoreUI
import MailResources
import RealmSwift
import SwiftUI
import WrappingHStack

extension VerticalAlignment {
    private enum IconAndTextFieldAlignment: AlignmentID {
        static func defaultValue(in d: ViewDimensions) -> CGFloat {
            d[VerticalAlignment.center]
        }
    }

    static let iconAndTextFieldAlignment = VerticalAlignment(IconAndTextFieldAlignment.self)
}

struct RecipientField: View {
    @FocusState var focusedField: ComposeViewFieldType?

    @Binding var currentText: String
    @Binding var recipients: RealmSwift.List<Recipient>

    let type: ComposeViewFieldType
    var onSubmit: (() -> Void)?

    private var isCurrentFieldFocused: Bool {
        if case .chip(let hash, _) = focusedField {
            return type.hashValue == hash
        }
        return type == focusedField
    }

    private var isExpanded: Bool {
        return isCurrentFieldFocused || recipients.isEmpty
    }

    private var shouldDisplayEmptyButton: Bool {
        return isCurrentFieldFocused && !currentText.isEmpty
    }

    var body: some View {
        HStack(alignment: .iconAndTextFieldAlignment, spacing: 0) {
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
                    .alignmentGuide(.iconAndTextFieldAlignment) { d in
                        d[VerticalAlignment.center]
                    }
                    .padding(.top, isCurrentFieldFocused && !recipients.isEmpty ? IKPadding.extraSmall : 0)
                    .padding(.top, IKPadding.recipientChip.top)
                    .padding(.bottom, IKPadding.recipientChip.bottom)
                    .frame(width: isExpanded ? nil : 0, height: isExpanded ? nil : 0)
            }
            .padding(.vertical, value: .intermediate)

            Button {
                currentText = ""
            } label: {
                MailResourcesAsset.remove
                    .iconSize(.medium)
                    .padding(value: .medium)
            }
            .foregroundStyle(MailResourcesAsset.textTertiaryColor)
            .opacity(shouldDisplayEmptyButton ? 1 : 0)
            .alignmentGuide(.iconAndTextFieldAlignment) { d in
                d[VerticalAlignment.center]
            }
        }
    }

    private func handleBackspaceTextField(isTextEmpty: Bool) {
        if let recipient = recipients.last, isTextEmpty {
            focusedField = .chip(type.hashValue, recipient)
        }
    }
}

#Preview {
    RecipientField(currentText: .constant(""), recipients: .constant(PreviewHelper.sampleRecipientsList), type: .to)
}
