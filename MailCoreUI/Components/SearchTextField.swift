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
import SwiftUI

public struct SearchTextField: View {
    @State private var initialFocusDone = false

    @Binding var value: String

    let onSubmit: () -> Void
    let onDelete: () -> Void

    public init(value: Binding<String>, onSubmit: @escaping () -> Void, onDelete: @escaping () -> Void) {
        _value = value
        self.onSubmit = onSubmit
        self.onDelete = onDelete
    }

    public var body: some View {
        HStack(spacing: UIPadding.small) {
            Button(action: onSubmit) {
                IKIcon(MailResourcesAsset.search)
                    .foregroundStyle(MailResourcesAsset.textTertiaryColor)
            }
            TextField(MailResourcesStrings.Localizable.searchFieldPlaceholder, text: $value)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .foregroundStyle(value.isEmpty
                    ? MailResourcesAsset.textTertiaryColor
                    : MailResourcesAsset.textPrimaryColor)
                .onSubmit {
                    onSubmit()
                }
                .introspect(.textField, on: .iOS(.v15, .v16, .v17)) { textField in
                    guard !initialFocusDone else { return }
                    DispatchQueue.main.async {
                        textField.becomeFirstResponder()
                        initialFocusDone = true
                    }
                }
                .padding(.vertical, value: .intermediate)

            Button(action: onDelete) {
                IKIcon(MailResourcesAsset.remove)
                    .foregroundStyle(MailResourcesAsset.textTertiaryColor)
            }
            .opacity(value.isEmpty ? 0 : 1)
        }
        .padding(.horizontal, value: .intermediate)
        .background {
            RoundedRectangle(cornerRadius: 27)
                .foregroundStyle(MailResourcesAsset.textFieldColor)
        }
    }
}

#Preview {
    SearchTextField(
        value: .constant("Recherche"),
        onSubmit: { /* Empty on purpose */ },
        onDelete: { /* Empty on purpose */ }
    )
}
