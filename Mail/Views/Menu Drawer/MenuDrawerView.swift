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

struct MenuDrawerView: View {
    @Environment(\.openURL) var openURL

    // swiftlint:disable empty_count
    @ObservedResults(Folder.self, where: { $0.parentLink.count == 0 }) var folders

    @StateObject var mailboxManager: MailboxManager
    @State private var showMailboxes = false

    @Binding var selectedFolder: Folder?

    var isCompact: Bool
    let geometryProxy: GeometryProxy

    private var helpMenuItems = [MenuItem]()
    private var actionsMenuItems = [MenuItem]()

    init(mailboxManager: MailboxManager, selectedFolder: Binding<Folder?>, isCompact: Bool, geometryProxy: GeometryProxy) {
        _folders = .init(Folder.self, configuration: AccountManager.instance.currentMailboxManager!.realmConfiguration) { $0.parentLink.count == 0 }
        _mailboxManager = StateObject(wrappedValue: mailboxManager)
        _selectedFolder = selectedFolder
        self.isCompact = isCompact
        self.geometryProxy = geometryProxy

        getMenuItems()
    }

    var body: some View {
        ScrollView {
            MenuHeaderView()

            VStack(alignment: .leading) {
                MailboxesManagementView()

                SeparatorView()

                RoleFoldersListView(folders: $folders, selectedFolder: $selectedFolder, isCompact: isCompact, geometryProxy: geometryProxy)

                SeparatorView()

                UserFoldersListView(folders: $folders, selectedFolder: $selectedFolder, isCompact: isCompact, geometryProxy: geometryProxy)

                SeparatorView()

                MenuDrawerItemsListView(content: helpMenuItems)

                SeparatorView()

                MenuDrawerItemsListView(title: MailResourcesStrings.menuDrawerAdvancedActions, content: actionsMenuItems)

                if mailboxManager.mailbox.isLimited {
                    SeparatorView()
                    MailboxQuotaView()
                }
            }
            .padding([.leading, .trailing], Constants.menuDrawerHorizontalPadding)
        }
        .background(Color(MailResourcesAsset.backgroundColor.color))
        .environmentObject(mailboxManager)
        .task {
            await fetchFolders()
            if selectedFolder == nil {
                selectedFolder = folders.first { $0.role == .inbox }
            }
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
