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
    let icon: MailResourcesImages
    let text: String
    let detailNumber: Int?
    let handleAction: () -> Void

    init(icon: MailResourcesImages, text: String, detailNumber: Int? = nil, handleAction: @escaping () -> Void) {
        self.icon = icon
        self.text = text
        self.detailNumber = detailNumber
        self.handleAction = handleAction
    }

    var body: some View {
        Button(action: handleAction) {
            HStack(spacing: 16) {
                Image(resource: icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundColor(.accentColor)
                Text(text)
                    .textStyle(.body)
                    .lineLimit(1)
                Spacer()
                if let detailNumber = detailNumber {
                    Text(detailNumber < 100 ? "\(detailNumber)" : "99+")
                        .textStyle(.bodySmallMediumAccent)
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, Constants.menuDrawerHorizontalPadding)
    }
}

struct MailboxesManagementButtonView_Previews: PreviewProvider {
    static var previews: some View {
        MailboxesManagementButtonView(icon: MailResourcesAsset.folder, text: "Hello") { /* Empty for test */ }
        MailboxesManagementButtonView(icon: MailResourcesAsset.folder, text: "Hello", detailNumber: 10) { /* Empty for test */ }
    }
}
