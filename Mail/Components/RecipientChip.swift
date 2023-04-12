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
import SwiftUI

import Popovers

struct RecipientChip: View {
    @State private var showPopover = false

    let recipient: Recipient
    let removeHandler: () -> Void

    @AppStorage(UserDefaults.shared.key(.accentColor)) private var accentColor = DefaultPreferences.accentColor

    var body: some View {
        Templates.Menu {
            RecipientCell(recipient: recipient)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)

            Templates.MenuDivider()

            Templates.MenuButton(text: Text(MailResourcesStrings.Localizable.contactActionCopyEmailAddress),
                                 image: MailResourcesAsset.duplicate.swiftUIImage) {
                UIPasteboard.general.string = recipient.email
                IKSnackBar.showSnackBar(message: MailResourcesStrings.Localizable.snackbarEmailCopiedToClipboard)
            }

            Templates.MenuButton(text: Text(MailResourcesStrings.Localizable.actionDelete),
                                 image: MailResourcesAsset.bin.swiftUIImage) {
                removeHandler()
            }
        } label: { _ in
            Text(recipient.name.isEmpty ? recipient.email : recipient.name)
                .textStyle(.bodyAccent)
                .lineLimit(1)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill(accentColor.secondary.swiftUIColor))
        }


//        Text(recipient.name.isEmpty ? recipient.email : recipient.name)
//            .textStyle(.bodyAccent)
//            .lineLimit(1)
//            .padding(.horizontal, 8)
//            .padding(.vertical, 4)
//            .background(Capsule().fill(accentColor.secondary.swiftUIColor))
//            .onTapGesture {
//                showPopover = true
//            }
//            .popover(present: $showPopover) {
//                Templates.MenuItem {
//                    print("hello")
//                } label: { _ in
//                    Text("Hello")
//                }
//
//
//                RecipientContextMenu(recipient: recipient) {
//                    showPopover = false
//                    removeHandler()
//                }
//            }
    }
}

struct RecipientContextMenu: View {
    let recipient: Recipient
    let removeHandler: () -> Void

    var body: some View {
        Button {
            UIPasteboard.general.string = recipient.email
            IKSnackBar.showSnackBar(message: MailResourcesStrings.Localizable.snackbarEmailCopiedToClipboard)
        } label: {
            Label(MailResourcesStrings.Localizable.contactActionCopyEmailAddress, image: MailResourcesAsset.duplicate.name)
        }

        Button {
            removeHandler()
        } label: {
            Label(MailResourcesStrings.Localizable.actionDelete, image: MailResourcesAsset.bin.name)
        }
    }
}

struct RecipientDetailsModifier: ViewModifier {
    let recipient: Recipient
    let removeHandler: () -> Void

    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content
                .contextMenu {
                    RecipientContextMenu(recipient: recipient, removeHandler: removeHandler)
                } preview: {
                    RecipientCell(recipient: recipient)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                }
        } else {
            content
                .contextMenu { RecipientContextMenu(recipient: recipient, removeHandler: removeHandler) }
        }
    }
}

struct RecipientChip_Previews: PreviewProvider {
    static var previews: some View {
        RecipientChip(recipient: PreviewHelper.sampleRecipient1) { /* Preview */ }
    }
}
