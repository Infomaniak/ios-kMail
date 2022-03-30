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
import MailCore
import MailResources
import RealmSwift
import SwiftUI
import UIKit

struct MenuDrawerView: View {
    @State private var showMailboxes = false

    // swiftlint:disable empty_count
    @ObservedResults(Folder.self, where: { $0.parentLink.count == 0 }) var folders
    private var mailboxManager: MailboxManager
    private weak var splitViewController: UISplitViewController?

    init(mailboxManager: MailboxManager, splitViewController: UISplitViewController) {
        self.mailboxManager = mailboxManager
        // swiftlint:disable empty_count
        _folders = .init(Folder.self, configuration: mailboxManager.realmConfiguration) { $0.parentLink.count == 0 }
        self.splitViewController = splitViewController
    }

    var body: some View {
        VStack {
            MenuHeaderView(splitViewController: splitViewController)

            MailboxesManagementView(mailboxManager: mailboxManager)

            List(AnyRealmCollection(folders), children: \.listChildren) { folder in
                Button {
                    updateSplitView(with: folder)
                } label: {
                    HStack {
                        Image(systemName: "tray")
                            .foregroundColor(Color(InfomaniakCoreAsset.infomaniakColor.color))
                        Text(folder.localizedName)
                        Spacer()
                        if let unreadCount = folder.unreadCount, unreadCount > 0 {
                            Text(unreadCount < 100 ? "\(unreadCount)" : "99+")
                        }
                    }
                }
            }
            .listStyle(.plain)
            .accentColor(Color(InfomaniakCoreAsset.infomaniakColor.color))
            .onAppear {
                Task {
                    await fetchFolders()
                    MatomoUtils.track(view: ["MenuDrawer"])
                }
            }

            MailboxQuotaView(mailboxManager: mailboxManager)
                .padding()
        }
    }

    // MARK: - Private functions

    private func updateSplitView(with folder: Folder) {
        let messageListVC = ThreadListViewController(mailboxManager: mailboxManager, folder: folder)
        splitViewController?.setViewController(messageListVC, for: .supplementary)
    }

    private func fetchFolders() async {
        do {
            try await mailboxManager.folders()
        } catch {
            print("Error while getting folders: \(error.localizedDescription)")
        }
    }

    // MARK: - Menu actions
}

private struct MenuHeaderView: View {
    var splitViewController: UISplitViewController?

    var body: some View {
        HStack {
            Text("Infomaniak Mail")
            Spacer()
            Button {
                splitViewController?.setViewController(SettingsViewController(), for: .secondary)
            } label: {
                Image(systemName: "gearshape")
            }
        }
        .padding()
    }
}

private struct MailboxesManagementView: View {
    @State private var unfoldDetails = false

    var mailboxManager: MailboxManager

    var body: some View {
        DisclosureGroup(isExpanded: $unfoldDetails) {
            VStack(alignment: .leading) {
                ForEach(AccountManager.instance.mailboxes.filter { $0.mailboxId != mailboxManager.mailbox.mailboxId }, id: \.mailboxId) { mailbox in
                    Button {
                        print("Update account")
                    } label: {
                        Text(mailbox.email)
                        Spacer()
                        Text("2")
                    }
                }

                Divider()

                Button("Ajouter un compte") {}
                Button("Gérer mon compte") {}
            }
            .padding(.leading)
        } label: {
            Text(mailboxManager.mailbox.email)
                .bold()
                .lineLimit(1)
        }
        .accentColor(.primary)
        .padding()
    }
}
