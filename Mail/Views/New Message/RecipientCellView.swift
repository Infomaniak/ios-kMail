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

enum RecipientCellType {
    case to, cc, bcc, object

    var title: String {
        switch self {
        case .to:
            return MailResourcesStrings.toTitle
        case .cc:
            return MailResourcesStrings.ccTitle
        case .bcc:
            return MailResourcesStrings.bccTitle
        case .object:
            return MailResourcesStrings.objectTitle
        }
    }
}

struct RecipientCellView: View {
    @Binding var draft: Draft
    @Binding var showCcButton: Bool

    let type: RecipientCellType

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(type.title)
                    .textStyle(.bodySecondary)

                switch type {
                case .to:
                    HStack {
                        TextField("", text: $draft.toValue)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .multilineTextAlignment(.leading)

                        Button {
                            showCcButton.toggle()
                        } label: {
                            if showCcButton {
                                Image(uiImage: MailResourcesAsset.chevronDown.image)
                            } else {
                                Image(uiImage: MailResourcesAsset.chevronDown.image).rotationEffect(Angle(degrees: 180))
                            }
                        }
                    }
                case .cc:
                    TextField("", text: $draft.ccValue)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                case .bcc:
                    TextField("", text: $draft.bccValue)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                case .object:
                    TextField("", text: $draft.subjectValue)
                }
            }
            .textStyle(.body)

            SeparatorView(withPadding: false, fullWidth: true)
        }
    }
}

struct RecipientCellView_Previews: PreviewProvider {
    static var previews: some View {
        RecipientCellView(draft: .constant(Draft()), showCcButton: .constant(false), type: .to)
            .previewLayout(.sizeThatFits)
    }
}
