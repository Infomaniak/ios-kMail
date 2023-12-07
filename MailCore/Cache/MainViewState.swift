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

import Foundation

@MainActor public final class MainViewState: ObservableObject {
    @Published public var editedDraft: EditedDraft?
    @Published public var messagesToMove: [Message]?
    @Published public var isShowingSearch = false
    @Published public var isShowingReviewAlert = false

    /// Represents the state of navigation
    ///
    /// The selected thread is the last in collection, by convention.
    @Published public var threadPath = [Thread]()
    @Published public private(set) var detachedSelectedFolder: Folder {
        didSet {
            SentryDebug.switchFolderBreadcrumb(uid: detachedSelectedFolder.remoteId, name: detachedSelectedFolder.name)
        }
    }

    public var frozenSelectedFolder: Folder? {
        guard let folder = mailboxManager.getRealm().object(ofType: Folder.self,
                                                            forPrimaryKey: detachedSelectedFolder.remoteId)?.freeze(),
            !folder.isInvalidated else {
            return nil
        }

        return folder
    }

    public func setDetachedSelectedFolder(_ folder: Folder) {
        assert(folder.realm == nil, "folder should be detached")
        detachedSelectedFolder = folder
    }

    let mailboxManager: MailboxManager
    public init(mailboxManager: MailboxManager, selectedFolder: Folder) {
        self.mailboxManager = mailboxManager
        detachedSelectedFolder = selectedFolder.detached()
    }
}
