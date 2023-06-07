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
    @Environment(\.mailboxCellStyle) private var style: MailboxCell.Style

    let icon: Image
    let text: String
    let detailNumber: Int?
    let handleAction: () -> Void
    let isSelected: Bool
    let isPasswordValid: Bool

    init(
        icon: MailResourcesImages,
        text: String,
        detailNumber: Int? = nil,
        isSelected: Bool,
        isPasswordValid: Bool,
        handleAction: @escaping () -> Void
    ) {
        self.icon = icon.swiftUIImage
        self.text = text
        self.detailNumber = detailNumber
        self.isSelected = isSelected
        self.isPasswordValid = isPasswordValid
        self.handleAction = handleAction
    }

    var body: some View {
        Button(action: handleAction) {
            HStack {
                HStack(spacing: 16) {
                    icon
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundColor(.accentColor)
                    Text(text)
                        .textStyle(.body)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if !isPasswordValid {
                    MailResourcesAsset.warning.swiftUIImage
                } else {
                    switch style {
                    case .menuDrawer:
                        if let detailNumber {
                            Text(detailNumber < 100 ? "\(detailNumber)" : "99+")
                                .textStyle(.bodySmallMediumAccent)
                        }
                    case .account:
                        if isSelected {
                            MailResourcesAsset.check.swiftUIImage
                                .frame(width: 16, height: 16)
                                .foregroundColor(.accentColor)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 10)
    }
}

struct MailboxesManagementButtonView_Previews: PreviewProvider {
    static var previews: some View {
        MailboxesManagementButtonView(icon: MailResourcesAsset.folder, text: "Hello", isSelected: false, isPasswordValid: true) {
            /* Empty for test */
        }
        MailboxesManagementButtonView(
            icon: MailResourcesAsset.folder,
            text: "Hello",
            detailNumber: 10,
            isSelected: false,
            isPasswordValid: true
        ) {
            /* Empty for test */
        }
    }
}
