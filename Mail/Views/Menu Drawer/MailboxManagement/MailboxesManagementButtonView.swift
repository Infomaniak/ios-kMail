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
import SwiftUI

struct MailboxesManagementButtonView: View {
    @State var text: String
    @Binding var detail: Int?

    var handleAction: () -> Void

    init(text: String, detail: Binding<Int?> = .constant(nil), handleAction: @escaping () -> Void) {
        _text = State(initialValue: text)
        _detail = detail
        self.handleAction = handleAction
    }

    var body: some View {
        Button(action: handleAction) {
            Text(text)
                .lineLimit(1)

            Spacer()

            if let detail = detail, detail > 0 {
                Text("\(detail)")
                    .foregroundColor(Color(InfomaniakCoreAsset.infomaniakColor.color))
            }
        }
        .padding([.top, .bottom], 5)
    }
}

struct MailboxesManagementButtonView_Previews: PreviewProvider {
    static var previews: some View {
        MailboxesManagementButtonView(text: "Hello") {
            print("Hello")
        }
        .previewLayout(.sizeThatFits)
    }
}
