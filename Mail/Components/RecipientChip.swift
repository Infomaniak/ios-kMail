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

import InfomaniakCoreUI
import MailCore
import MailResources
import Popovers
import SwiftUI

struct RecipientChip: View {
    @Environment(\.window) private var window

    let recipient: Recipient
    let isFocused: Bool
    let removeHandler: () -> Void

    @AppStorage(UserDefaults.shared.key(.accentColor)) private var accentColor = DefaultPreferences.accentColor

    var body: some View {
        Templates.Menu {
            $0.width = nil
            $0.originAnchor = .topLeft
        } content: {
            RecipientCell(recipient: recipient)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .frame(maxWidth: min(300, window?.screen.bounds.width ?? 300))

            Templates.MenuButton(text: Text(MailResourcesStrings.Localizable.contactActionCopyEmailAddress),
                                 image: MailResourcesAsset.duplicate.swiftUIImage) {
                UIPasteboard.general.string = recipient.email
                IKSnackBar.showSnackBar(message: MailResourcesStrings.Localizable.snackbarEmailCopiedToClipboard)
            }

            Templates.MenuButton(text: Text(MailResourcesStrings.Localizable.actionDelete),
                                 image: MailResourcesAsset.bin.swiftUIImage) {
                removeHandler()
            }
        } label: { isSelected in
            Text(recipient.name.isEmpty ? recipient.email : recipient.name)
                .textStyle(isFocused ? .bodyAccentSecondary : .bodyAccent)
                .lineLimit(1)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill(isFocused ? Color.accentColor : accentColor.secondary.swiftUIColor))
                .opacity(isSelected ? 0.8 : 1)
        }
    }
}

struct RecipientChip_Previews: PreviewProvider {
    static var previews: some View {
        RecipientChip(recipient: PreviewHelper.sampleRecipient1, isFocused: false) { /* Preview */ }
    }
}
