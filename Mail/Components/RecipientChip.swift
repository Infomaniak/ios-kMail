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

struct RecipientChip: View {
    let recipient: Recipient
    let removeButtonTapped: () -> Void

    @AppStorage(UserDefaults.shared.key(.accentColor)) private var accentColor = DefaultPreferences.accentColor

    var body: some View {
        Text(recipient.name.isEmpty ? recipient.email : recipient.name)
            .textStyle(.bodyAccent)
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Capsule().fill(accentColor.secondary.swiftUIColor))
            .modifier(RecipientDetailsModifier())
    }
}

struct RecipientContextMenu: View {
    var body: some View {
        Button {
            // Copy mail address
        } label: {
            Label(MailResourcesStrings.Localizable.contactActionCopyEmailAddress, image: MailResourcesAsset.duplicate.name)
        }

        Button {
            // Remove recipient
        } label: {
            Label(MailResourcesStrings.Localizable.actionDelete, image: MailResourcesAsset.bin.name)
        }
    }
}

struct RecipientDetailsModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content
                .contextMenu {
                    RecipientContextMenu()
                } preview: {
                    Text("Contact Preview")
                }
        } else {
            content
                .contextMenu { RecipientContextMenu() }
        }
    }
}

struct RecipientChip_Previews: PreviewProvider {
    static var previews: some View {
        RecipientChip(recipient: PreviewHelper.sampleRecipient1) { /* Preview */ }
    }
}
