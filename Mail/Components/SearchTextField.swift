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

import MailResources
import SwiftUI

struct SearchTextField: View {
    @Binding public var value: String
    @Binding public var isFocused: Bool
    public var onSubmit: () -> Void
    public var onDelete: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onSubmit) {
                Image(resource: MailResourcesAsset.search)
                    .resizable()
                    .frame(width: 16, height: 16)
            }
            .foregroundColor(MailResourcesAsset.textFieldPlaceholderColor)
            TextField(MailResourcesStrings.Localizable.searchFieldPlaceholder, text: $value) { focused in
                isFocused = focused
            }
            .autocorrectionDisabled()
            .textFieldStyle(DefaultTextFieldStyle())
            .foregroundColor(value.isEmpty
                ? MailResourcesAsset.textFieldPlaceholderColor
                : MailResourcesAsset.primaryTextColor)
            .onSubmit {
                onSubmit()
            }
            .padding(.vertical, 11)

            Button(action: onDelete) {
                Image(resource: MailResourcesAsset.plus)
                    .resizable()
                    .frame(width: 18, height: 18)
                    .rotationEffect(Angle(degrees: 45))
            }
            .foregroundColor(MailResourcesAsset.textFieldPlaceholderColor)
            .opacity(value.isEmpty ? 0 : 1)
        }
        .padding(.horizontal, 12)
        .background {
            RoundedRectangle(cornerRadius: 27)
                .foregroundColor(MailResourcesAsset.textFieldColor)
        }
    }
}

struct SearchTextField_Previews: PreviewProvider {
    static var previews: some View {
        SearchTextField(
            value: .constant("Recherche"),
            isFocused: .constant(false),
            onSubmit: { /* Empty on purpose */ },
            onDelete: { /* Empty on purpose */ }
        )
    }
}
