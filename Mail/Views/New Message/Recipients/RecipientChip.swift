/*
 Infomaniak Mail - iOS App
 Copyright (C) 2024 Infomaniak Network SA

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import InfomaniakDI
import MailCore
import MailCoreUI
import MailResources
import Popovers
import SwiftUI

struct RecipientChip: View {
    @Environment(\.currentUser) private var currentUser
    @EnvironmentObject private var mailboxManager: MailboxManager

    @LazyInjectService private var snackbarPresenter: SnackBarPresentable

    let recipient: Recipient
    let fieldType: ComposeViewFieldType
    // periphery:ignore - Used in removeAndFocus
    @FocusState var focusedField: ComposeViewFieldType?
    var removeHandler: (() -> Void)?
    var switchFocusHandler: (() -> Void)?

    var body: some View {
        Templates.Menu {
            $0.width = nil
            $0.originAnchor = .topLeft
            $0.popoverAnchor = .topLeft
        } content: {
            RecipientCell(recipient: recipient, contextUser: currentUser.value, contextMailboxManager: mailboxManager)
                .padding(.vertical, value: .mini)
                .padding(.horizontal, value: .medium)
                .frame(maxWidth: 600)
                .environment(\.currentUser, currentUser)
                .environmentObject(mailboxManager)

            Templates.MenuButton(text: Text(MailResourcesStrings.Localizable.contactActionCopyEmailAddress),
                                 image: MailResourcesAsset.duplicate.swiftUIImage) {
                UIPasteboard.general.string = recipient.email
                snackbarPresenter.show(message: MailResourcesStrings.Localizable.snackbarEmailCopiedToClipboard)
            }

            Templates.MenuButton(text: Text(MailResourcesStrings.Localizable.actionDelete),
                                 image: MailResourcesAsset.bin.swiftUIImage) {
                removeHandler?()
            }
        } label: { isSelected in
            RecipientChipLabelView(
                recipient: recipient,
                type: recipient.isExternal(mailboxManager: mailboxManager) ? .external : .default,
                removeHandler: removeAndFocus,
                switchFocusHandler: switchFocusHandler
            )
            .opacity(isSelected ? 0.8 : 1)
        }
    }

    private func removeAndFocus() {
        focusedField = fieldType
        removeHandler?()
    }
}

#Preview {
    RecipientChip(recipient: PreviewHelper.sampleRecipient1, fieldType: .to) {
        /* Preview */
    } switchFocusHandler: {
        /* Preview */
    }
}
