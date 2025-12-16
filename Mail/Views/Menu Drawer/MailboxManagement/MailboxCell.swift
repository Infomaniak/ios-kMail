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

import InfomaniakCore
import InfomaniakCoreCommonUI
import InfomaniakDI
import MailCore
import MailCoreUI
import MailResources
import SwiftModalPresentation
import SwiftUI

extension EnvironmentValues {
    @Entry
    var mailboxCellStyle = MailboxCell.Style.menuDrawer
}

extension View {
    func mailboxCellStyle(_ style: MailboxCell.Style) -> some View {
        environment(\.mailboxCellStyle, style)
    }
}

struct MailboxCell: View {
    @Environment(\.mailboxCellStyle) private var style: Style
    @EnvironmentObject private var navigationDrawerState: NavigationDrawerState

    @ModalState private var isShowingLockedView = false

    let mailbox: Mailbox
    var isSelected = false

    enum Style {
        case menuDrawer, account, locked
    }

    var body: some View {
        MailboxesManagementButtonView(
            icon: MailResourcesAsset.envelope,
            mailbox: mailbox,
            isSelected: isSelected
        ) {
            guard !isSelected else { return }
            guard !mailbox.isLocked else {
                isShowingLockedView = true
                return
            }

            @InjectService var accountManager: AccountManager
            @InjectService var matomo: MatomoUtils

            switch style {
            case .locked:
                return
            case .menuDrawer:
                matomo.track(eventWithCategory: .menuDrawer, name: "switchMailbox")
            case .account:
                matomo.track(eventWithCategory: .account, name: "switchMailbox")
            }
            accountManager.switchMailbox(newMailbox: mailbox)
            navigationDrawerState.close()
        }
        .mailFloatingPanel(isPresented: $isShowingLockedView) {
            LockedMailboxView(email: mailbox.email)
        }
    }
}

#Preview {
    MailboxCell(mailbox: PreviewHelper.sampleMailbox, isSelected: true)
}
