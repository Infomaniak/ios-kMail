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

    @State var selectedFolderId: String?
    @State private var showMailboxes = false

    var isCompact: Bool
    weak var delegate: FolderListViewDelegate?

    private var helpMenuItems = [MenuItem]()
    private var actionsMenuItems = [MenuItem]()

    init(selectedFolderId: String?, isCompact: Bool, delegate: FolderListViewDelegate? = nil) {
        self.isCompact = isCompact
        self.delegate = delegate
        _selectedFolderId = State(initialValue: selectedFolderId)

        getMenuItems()
    }

    var body: some View {
        ScrollView {
            MenuHeaderView()

            VStack(alignment: .leading) {
                MailboxesManagementView()

                MenuDrawerSeparatorView()

                RoleFoldersListView(selectedFolderId: $selectedFolderId, isCompact: isCompact, delegate: delegate)

                MenuDrawerSeparatorView()

                UserFoldersListView(selectedFolderId: $selectedFolderId, isCompact: isCompact, delegate: delegate)

                MenuDrawerSeparatorView()

                ItemsListView(content: helpMenuItems)

                MenuDrawerSeparatorView()

                ItemsListView(title: "Actions avancées", content: actionsMenuItems)

                if accountManager.currentMailboxManager?.mailbox.isLimited == true {
                    MailboxQuotaView()
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
