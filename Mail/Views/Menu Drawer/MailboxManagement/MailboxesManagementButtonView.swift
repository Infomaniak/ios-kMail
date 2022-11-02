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
import MailCore
import MailResources
import SwiftUI

struct MailboxesManagementButtonView: View {
    let text: String
    let detailNumber: Int?
    let handleAction: () -> Void

    init(text: String, detailNumber: Int? = nil, handleAction: @escaping () -> Void) {
        self.text = text
        self.detailNumber = detailNumber
        self.handleAction = handleAction
    }

    var body: some View {
        Button(action: handleAction) {
            HStack {
                Text(text)
                    .textStyle(.header5)
                    .lineLimit(1)
                Spacer()
                if let detailNumber = detailNumber {
                    Text(detailNumber < 100 ? "\(detailNumber)" : "99+")
                        .textStyle(.calloutMediumAccent)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.leading, 68)
        .padding(.trailing, Constants.menuDrawerHorizontalPadding)
    }
}

struct MailboxesManagementButtonView_Previews: PreviewProvider {
    static var previews: some View {
        MailboxesManagementButtonView(text: "Hello") { /* Empty for test */ }
        MailboxesManagementButtonView(text: "Hello", detailNumber: 10) { /* Empty for test */ }
    }
}
