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

    // swiftlint:disable empty_count
    @ObservedResults(Folder.self, where: { $0.parentLink.count == 0 }) var folders

    @StateObject var mailboxManager: MailboxManager

    @State var selectedFolderId: String?
    @State private var showMailboxes = false

    var isCompact: Bool
    weak var delegate: FolderListViewDelegate?

    private var helpMenuItems = [MenuItem]()
    private var actionsMenuItems = [MenuItem]()

    init(mailboxManager: MailboxManager, selectedFolderId: String?, isCompact: Bool, delegate: FolderListViewDelegate? = nil) {
        _folders = .init(Folder.self, configuration: AccountManager.instance.currentMailboxManager!.realmConfiguration) { $0.parentLink.count == 0 }
        _mailboxManager = StateObject(wrappedValue: mailboxManager)
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

                RoleFoldersListView(folders: $folders, selectedFolderId: $selectedFolderId, isCompact: isCompact, delegate: delegate)

                MenuDrawerSeparatorView()

                UserFoldersListView(folders: $folders, selectedFolderId: $selectedFolderId, isCompact: isCompact, delegate: delegate)

                MenuDrawerSeparatorView()

                MenuDrawerItemsListView(content: helpMenuItems)

                MenuDrawerSeparatorView()

                MenuDrawerItemsListView(title: MailResourcesStrings.menuDrawerAdvancedActions, content: actionsMenuItems)

                if mailboxManager.mailbox.isLimited {
                    MenuDrawerSeparatorView()
                    MailboxQuotaView()
                }
            }
            .padding([.leading, .trailing], Self.horizontalPadding)
        }
        .environmentObject(mailboxManager)
        .task {
            await fetchFolders()
            MatomoUtils.track(view: ["MenuDrawer"])
        }
    }

    // MARK: - Private methods

    private mutating func getMenuItems() {
        helpMenuItems = [
            MenuItem(icon: MailResourcesAsset.alertCircle, label: MailResourcesStrings.buttonFeedbacks, action: sendFeedback),
            MenuItem(icon: MailResourcesAsset.questionHelpCircle, label: MailResourcesStrings.buttonHelp, action: openSupport)
        ]
        actionsMenuItems = [
            MenuItem(icon: MailResourcesAsset.drawerArrow, label: MailResourcesStrings.buttonImportEmails, action: importMails),
            MenuItem(icon: MailResourcesAsset.synchronizeArrow, label: MailResourcesStrings.buttonRestoreEmails, action: restoreMails)
        ]
    }

    private func fetchFolders() async {
        do {
            try await mailboxManager.folders()
        } catch {
            print("Error while fetching folders: \(error.localizedDescription)")
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
        // TODO: Display "Restore Mails" view
    }
}
