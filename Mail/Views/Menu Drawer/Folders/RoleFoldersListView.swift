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

struct RoleFoldersListView: View {
    // swiftlint:disable empty_count
    @ObservedResults(Folder.self, where: { $0.parentLink.count == 0 && $0.role != nil }) var folders

    @EnvironmentObject var accountManager: AccountManager

    @Binding var selectedFolderId: String?

    var isCompact: Bool

    weak var delegate: FolderListViewDelegate?

    private let items: [FolderRole: MailResourcesImages] = [
        .inbox: MailResourcesAsset.drawer,
        .commercial: MailResourcesAsset.commercial,
        .socialNetworks: MailResourcesAsset.socialNetworks,
        .sent: MailResourcesAsset.emailSent,
        .draft: MailResourcesAsset.draft,
        .spam: MailResourcesAsset.spam,
        .trash: MailResourcesAsset.bin,
        .archive: MailResourcesAsset.archive
    ]

    init(selectedFolderId: Binding<String?>, isCompact: Bool, delegate: FolderListViewDelegate?) {
        _folders = .init(Folder.self, configuration: AccountManager.instance.currentMailboxManager!.realmConfiguration) { $0.parentLink.count == 0 && $0.role != nil }
        _selectedFolderId = selectedFolderId
        self.isCompact = isCompact
        self.delegate = delegate
    }

    var body: some View {
        ForEach(AnyRealmCollection(folders).sorted()) { folder in
            FolderCell(folder: folder, selectedFolderId: $selectedFolderId, icon: items[folder.role!]!, isCompact: isCompact, delegate: delegate)
                .padding(.top, folder.role == .inbox ? 3 : Constants.menuDrawerFolderCellPadding)
                .padding(.bottom, folder.role == .inbox ? 0 : Constants.menuDrawerFolderCellPadding)

            if folder.role == .inbox {
                MenuDrawerSeparatorView()
            }
        }
    }
}
