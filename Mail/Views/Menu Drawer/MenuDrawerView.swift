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
import RealmSwift
import SwiftUI
import UIKit

struct MenuDrawerView: View {
    @State private var showMailboxes = false
    @State private var selectedFolderId: String?

    var mailboxManager: MailboxManager
    weak var splitViewController: UISplitViewController?

    public static let horizontalPadding: CGFloat = 25

    private let helpMenuItems = [
        MenuItem(icon: MailResourcesAsset.alertCircle, label: "Feedbacks", action: sendFeedback),
        MenuItem(icon: MailResourcesAsset.questionHelpCircle, label: "Aide", action: openHelp)
    ]
    private let actionsMenuItems = [
        MenuItem(icon: MailResourcesAsset.drawerArrow, label: "Importer des mails", action: importMails),
        MenuItem(icon: MailResourcesAsset.synchronizeArrow, label: "Restaurer des mails", action: restoreMails)
    ]

    var body: some View {
        ScrollView {
            MenuHeaderView(splitViewController: splitViewController)

            VStack(alignment: .leading) {
                MailboxesManagementView(mailbox: mailboxManager.mailbox)

                MenuDrawerSeparatorView()

                FoldersListView(mailboxManager: mailboxManager, splitViewController: splitViewController, selectedFolderId: $selectedFolderId)

                MenuDrawerSeparatorView()

                ItemsListView(content: helpMenuItems)

                MenuDrawerSeparatorView()

                ItemsListView(title: "Actions avancées", content: actionsMenuItems)

                if mailboxManager.mailbox.isLimited {
                    MailboxQuotaView(mailboxManager: mailboxManager)
                }
            }
            .padding([.leading, .trailing], Self.horizontalPadding)
        }
        .listStyle(.plain)
    }

    // MARK: - Menu actions

    static func sendFeedback() {
        // Send feedbacks
    }

    static func openHelp() {
        // Open help
    }

    static func importMails() {
        // Import Mails
    }

    static func restoreMails() {
        // Restore Mails
    }
}
