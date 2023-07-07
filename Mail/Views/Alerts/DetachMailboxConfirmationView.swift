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
import InfomaniakDI
import MailCore
import MailResources
import SwiftUI

struct DetachMailboxConfirmationView: View {
    @Environment(\.window) private var window

    let mailbox: Mailbox

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text(MailResourcesStrings.Localizable.popupDetachMailboxTitle)
                .textStyle(.bodyMedium)
            Text(mailbox.email)
                .textStyle(.bodySecondary)
            ModalButtonsView(primaryButtonTitle: MailResourcesStrings.Localizable.buttonDetach, primaryButtonAction: detach)
        }
    }

    private func detach() {
        @InjectService var matomo: MatomoUtils
        matomo.track(eventWithCategory: .invalidPasswordMailbox, name: "detachMailboxConfirm")

        Task {
            do {
                try await AccountManager.instance.detachMailbox(mailbox: mailbox)
                await (window?.windowScene?.delegate as? SceneDelegate)?.showMainView()
            } catch {
                print(error)
            }
        }
    }
}

struct DetachMailboxConfirmationView_Previews: PreviewProvider {
    static var previews: some View {
        DetachMailboxConfirmationView(mailbox: PreviewHelper.sampleMailbox)
    }
}
