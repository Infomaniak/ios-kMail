//
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
    case from, to, object

    var title: String {
        switch self {
        case .from:
            return "De :"
        case .to:
            return "À :"
        case .object:
            return "Objet :"
        }
    }
}

struct RecipientCellView: View {
    @State var from: String = ""
    @State var draft: Draft

    let type: RecipientCellType

    var body: some View {
        VStack {
            HStack {
                Text(type.title)

                switch type {
                case .from:
                    TextField("", text: $from)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                case .to:
                    TextField("", text: $draft.toValue)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                case .object:
                    TextField("", text: $draft.subjectValue)
                }
            }
            Divider()
                .background(Color(MailResourcesAsset.separatorColor.color))
        }
    }
}

struct RecipientCellView_Previews: PreviewProvider {
    static var previews: some View {
        RecipientCellView(draft: Draft(), type: RecipientCellType.from)
            .previewLayout(.sizeThatFits)
    }
}
