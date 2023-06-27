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
import InfomaniakCoreUI
import InfomaniakDI
import MailCore
import MailResources
import SwiftUI

struct MailboxCellStyleKey: EnvironmentKey {
    static var defaultValue = MailboxCell.Style.menuDrawer
}

extension EnvironmentValues {
    var mailboxCellStyle: MailboxCell.Style {
        get { self[MailboxCellStyleKey.self] }
        set { self[MailboxCellStyleKey.self] = newValue }
    }
}

extension View {
    func mailboxCellStyle(_ style: MailboxCell.Style) -> some View {
        environment(\.mailboxCellStyle, style)
    }
}

struct MailboxCell: View {
    @Environment(\.mailboxCellStyle) private var style: Style
    @Environment(\.window) private var window

    let mailbox: Mailbox
    var isSelected = false

    private var detailNumber: Int? {
        return mailbox.unseenMessages > 0 ? mailbox.unseenMessages : nil
    }

    private var inMaintenance: Bool {
        return !mailbox.isPasswordValid || mailbox.isLocked
    }

    enum Style {
        case menuDrawer, account
    }

    var body: some View {
        MailboxesManagementButtonView(
            icon: MailResourcesAsset.envelope,
            text: mailbox.email,
            detailNumber: detailNumber,
            isSelected: isSelected,
            isInMaintenance: inMaintenance
        ) {
            guard !isSelected else { return }
            guard mailbox.isPasswordValid else {
                IKSnackBar.showSnackBar(message: MailResourcesStrings.Localizable.frelatedMailbox)
                return
            }
            guard !mailbox.isLocked else {
                IKSnackBar.showSnackBar(message: MailResourcesStrings.Localizable.lockedMailboxesTitle)
                return
            }
            @InjectService var matomo: MatomoUtils
            switch style {
            case .menuDrawer:
                matomo.track(eventWithCategory: .menuDrawer, name: "switchMailbox")
            case .account:
                matomo.track(eventWithCategory: .account, name: "switchMailbox")
            }
            (window?.windowScene?.delegate as? SceneDelegate)?.switchMailbox(mailbox)
        }
    }
}

struct MailboxCell_Previews: PreviewProvider {
    static var previews: some View {
        MailboxCell(mailbox: PreviewHelper.sampleMailbox, isSelected: true)
    }
}
