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

struct SearchTextField: View {
    @State private var initialFocusDone = false

    @Binding public var value: String

    public var onSubmit: () -> Void
    public var onDelete: () -> Void

    var body: some View {
        HStack(spacing: UIPadding.small) {
            Button(action: onSubmit) {
                IKIcon(
                    size: .medium,
                    image: MailResourcesAsset.search,
                    shapeStyle: MailResourcesAsset.textTertiaryColor.swiftUIColor
                )
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
                IKIcon(
                    size: .medium,
                    image: MailResourcesAsset.remove,
                    shapeStyle: MailResourcesAsset.textTertiaryColor.swiftUIColor
                )
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

struct SearchTextField_Previews: PreviewProvider {
    static var previews: some View {
        SearchTextField(
            value: .constant("Recherche"),
            onSubmit: { /* Empty on purpose */ },
            onDelete: { /* Empty on purpose */ }
        )
    }
}
