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
    public var onSubmit: () -> Void
    public var onDelete: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button {
                onSubmit()
            } label: {
                Image(uiImage: MailResourcesAsset.search.image)
                    .frame(width: 16, height: 16)
            }
            .foregroundColor(MailResourcesAsset.textFieldPlaceholderColor)

            TextField("SearchField", text: $value)
                .textFieldStyle(DefaultTextFieldStyle())
                .foregroundColor(value.isEmpty
                    ? MailResourcesAsset.textFieldPlaceholderColor
                    : MailResourcesAsset.primaryTextColor)
                    .onSubmit {
                        onSubmit()
                    }
                    .padding(.vertical, 11)

            Button {
                onDelete()
            } label: {
                Image(uiImage: MailResourcesAsset.plus.image)
                    .rotationEffect(Angle(degrees: 45))
            }
            .foregroundColor(MailResourcesAsset.textFieldPlaceholderColor)
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
        SearchTextField(value: .constant("Recherche"), onSubmit: { /* Empty on purpose */ }, onDelete: { /* Empty on purpose */ })
    }
}
