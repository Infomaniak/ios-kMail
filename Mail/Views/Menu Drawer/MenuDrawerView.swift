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
    public static let horizontalPadding: CGFloat = 25

    @Environment(\.openURL) var openURL

    @StateObject var accountManager = AccountManager.instance

    @State private var showMailboxes = false
    @State private var selectedFolderId: String?

    var mailboxManager: MailboxManager
    weak var splitViewController: UISplitViewController?
    var isCompact: Bool
    weak var delegate: FolderListViewDelegate?

    private var helpMenuItems = [MenuItem]()
    private var actionsMenuItems = [MenuItem]()

    init(mailboxManager: MailboxManager, splitViewController: UISplitViewController? = nil, isCompact: Bool, delegate: FolderListViewDelegate? = nil) {
        self.mailboxManager = mailboxManager
        self.splitViewController = splitViewController
        self.isCompact = isCompact
        self.delegate = delegate

        getMenuItems()
    }

    var body: some View {
        ScrollView {
            MenuHeaderView(splitViewController: splitViewController)

            VStack(alignment: .leading) {
                MailboxesManagementView()

                MenuDrawerSeparatorView()

                RoleFoldersListView(delegate: delegate, selectedFolderId: $selectedFolderId)

                MenuDrawerSeparatorView()

                UserFoldersListView(mailboxManager: mailboxManager, delegate: delegate, selectedFolderId: $selectedFolderId)

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
        .environmentObject(accountManager)
        .onAppear {
            Task {
                await fetchFolders()
                MatomoUtils.track(view: ["MenuDrawer"])
            }
        }
        .onChange(of: accountManager.currentMailboxId) { _ in
            Task {
                await fetchFolders()
            }
        }
    }

    // MARK: - Private methods

    private mutating func getMenuItems() {
        helpMenuItems = [
            MenuItem(icon: MailResourcesAsset.alertCircle, label: "Feedbacks", action: sendFeedback),
            MenuItem(icon: MailResourcesAsset.questionHelpCircle, label: "Aide", action: openSupport)
        ]
        actionsMenuItems = [
            MenuItem(icon: MailResourcesAsset.drawerArrow, label: "Importer des mails", action: importMails),
            MenuItem(icon: MailResourcesAsset.synchronizeArrow, label: "Restaurer des mails", action: restoreMails)
        ]
    }

    private func fetchFolders() async {
        guard let mailboxManager = accountManager.currentMailboxManager else { return }
        do {
            try await mailboxManager.folders()
        } catch {
            print("Error while getting folders: \(error.localizedDescription)")
        }
    }

    // MARK: - Menu actions

    func sendFeedback() {
        openURL(URLConstants.feedback.url)
    }

    func openSupport() {
        openURL(URLConstants.support.url)
    }

    func importMails() {
        openURL(URLConstants.importMails.url)
    }

    func restoreMails() {
        // Restore mails
    }
}
