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

import InfomaniakBugTracker
import MailCore
import MailResources
import RealmSwift
import SwiftUI

struct NestableFolder: Identifiable {
    var id: String {
        content.id
    }

    let content: Folder
    let children: [NestableFolder]

    static func createFoldersHierarchy(from folders: [Folder]) -> [Self] {
        var parentFolders = [NestableFolder]()

        let sortedFolders = folders.sorted()
        for folder in sortedFolders {
            parentFolders.append(NestableFolder(
                content: folder,
                children: Self.createFoldersHierarchy(from: Array(folder.children))
            ))
        }

        return parentFolders
    }
}

class MenuDrawerViewModel: ObservableObject {
    /// User currently selected mailbox
    @Published var mailbox: Mailbox
    /// Other mailboxes the user owns
    @Published var mailboxes = [Mailbox]()
    /// Special folders (eg. Inbox) for the current mailbox
    @Published var roleFolders = [NestableFolder]()
    /// User created folders for the current mailbox
    @Published var userFolders = [NestableFolder]()

    @Published var helpMenuItems = [MenuItem]()
    @Published var actionsMenuItems = [MenuItem]()
    @Published var isShowingHelp = false
    @Published var isShowingBugTracker = false

    private var bottomSheet: GlobalBottomSheet?
    private var foldersObservationToken: NotificationToken?
    private var mailboxesObservationToken: NotificationToken?

    private let userFoldersSortDescriptors = [
        SortDescriptor(keyPath: \Folder.isFavorite, ascending: false),
        SortDescriptor(keyPath: \Folder.unreadCount, ascending: false),
        SortDescriptor(keyPath: \Folder.name)
    ]

    init(mailboxManager: MailboxManager) {
        if let liveMailbox = MailboxInfosManager.instance.getMailbox(objectId: mailboxManager.mailbox.objectId, freeze: false) {
            mailbox = liveMailbox
        } else {
            mailbox = mailboxManager.mailbox
        }

        mailboxesObservationToken = MailboxInfosManager.instance.getRealm()
            .objects(Mailbox.self)
            .where { $0.userId == AccountManager.instance.currentUserId }
            .sorted(by: \.mailboxId)
            .observe(on: DispatchQueue.main) { results in
                switch results {
                case .initial(let mailboxes):
                    self.mailboxes = Array(mailboxes)
                case .update(let mailboxes, _, _, _):
                    self.mailboxes = Array(mailboxes)
                case .error:
                    break
                }
            }

        // swiftlint:disable empty_count
        foldersObservationToken = mailboxManager.getRealm()
            .objects(Folder.self).where { $0.parentLink.count == 0 && $0.toolType == nil }
            .observe(on: DispatchQueue.main) { [weak self] results in
                switch results {
                case .initial(let folders):
                    self?.handleFoldersUpdate(folders)
                case .update(let folders, _, _, _):
                    withAnimation {
                        self?.handleFoldersUpdate(folders)
                    }
                case .error:
                    break
                }
            }
    }

    private func handleFoldersUpdate(_ folders: Results<Folder>) {
        roleFolders = NestableFolder.createFoldersHierarchy(from: Array(folders.where { $0.role != nil }))
        userFolders = NestableFolder.createFoldersHierarchy(from: Array(folders.where { $0.role == nil }))
    }

    func createMenuItems(bottomSheet: GlobalBottomSheet) {
        self.bottomSheet = bottomSheet

        helpMenuItems = [
            MenuItem(icon: MailResourcesAsset.feedback,
                     label: MailResourcesStrings.Localizable.buttonFeedback,
                     action: sendFeedback),
            MenuItem(icon: MailResourcesAsset.help,
                     label: MailResourcesStrings.Localizable.buttonHelp,
                     action: openHelp)
        ]

        actionsMenuItems = [
            MenuItem(icon: MailResourcesAsset.drawerDownload,
                     label: MailResourcesStrings.Localizable.buttonImportEmails,
                     action: importMails)
        ]
        if mailbox.permissions?.canRestoreEmails == true {
            actionsMenuItems.append(.init(
                icon: MailResourcesAsset.restoreArrow,
                label: MailResourcesStrings.Localizable.buttonRestoreEmails,
                action: restoreMails
            ))
        }
    }

    // MARK: - Menu actions

    private func sendFeedback() {
        if AccountManager.instance.currentAccount?.user?.isStaff == true {
            BugTracker.configureForMail()
            isShowingBugTracker.toggle()
        } else {
            UIApplication.shared.open(URLConstants.feedback.url)
        }
    }

    private func openHelp() {
        isShowingHelp.toggle()
    }

    private func importMails() {
        UIApplication.shared.open(URLConstants.importMails.url)
    }

    private func restoreMails() {
        bottomSheet?.open(state: .restoreEmails)
    }
}
