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

import Combine
import Foundation
import InfomaniakCore
import InfomaniakLogin
@testable import Mail
@testable import MailCore
@testable import RealmSwift
import XCTest

struct MCKMailboxManageable: MailboxManageable {
    let realm: Realm
    init(realm: Realm) {
        self.realm = realm
    }

    func draftWithPendingAction() -> RealmSwift.Results<MailCore.Draft> {
        fatalError("Unexpected")
    }

    func draft(messageUid: String, using realm: RealmSwift.Realm?) -> MailCore.Draft? { nil }

    func draft(localUuid: String, using realm: RealmSwift.Realm?) -> MailCore.Draft? { nil }

    func draft(remoteUuid: String, using realm: RealmSwift.Realm?) -> MailCore.Draft? { nil }

    func send(draft: MailCore.Draft) async throws -> MailCore.SendResponse {
        fatalError("Unexpected")
    }

    func save(draft: MailCore.Draft) async throws {}

    func delete(draft: MailCore.Draft) async throws {}

    func delete(draftMessage: MailCore.Message) async throws {}

    func deleteLocally(draft: MailCore.Draft) async throws {}

    func deleteOrphanDrafts() async {}

    func messages(folder: MailCore.Folder, isRetrying: Bool) async throws {}

    func fetchOnePage(folder: MailCore.Folder, direction: MailCore.NewMessagesDirection?) async throws -> Bool { false }

    func message(message: MailCore.Message) async throws {}

    func attachmentData(_ attachment: MailCore.Attachment) async throws -> Data { Data() }

    func saveAttachmentLocally(attachment: MailCore.Attachment) async {}

    func markAsSeen(message: MailCore.Message, seen: Bool) async throws {}

    func move(messages: [MailCore.Message], to folderRole: MailCore.FolderRole) async throws -> MailCore.UndoAction {
        fatalError("Unexpected")
    }

    func move(messages: [MailCore.Message], to folder: MailCore.Folder) async throws -> MailCore.UndoAction {
        fatalError("Unexpected")
    }

    func delete(messages: [MailCore.Message]) async throws {}

    var realmConfiguration: RealmSwift.Realm.Configuration {
        realm.configuration
    }

    func getRealm() -> Realm {
        realm
    }
}

/// Integration tests of the FolderListViewModel
final class ITFolderListViewModel: XCTestCase {
    @MainActor func testInitAndFetchFromDB() {
        // GIVEN
        let folderGenerator = FolderStructureGenerator(maxDepth: 5, maxElementsPerLevel: 5)
        let folderRealmResults = folderGenerator.inMemoryRealm.objects(Folder.self).freezeIfNeeded()
        print("generated \(folderRealmResults.count) folders")

        let mailboxManager = MCKMailboxManageable(realm: folderGenerator.inMemoryRealm)

        let roleFolderExpectation = XCTestExpectation(description: "[roleFolders] should be updated.")
        let userFolderExpectation = XCTestExpectation(description: "[userFolders] should be updated.")
        let asyncExpectations = [roleFolderExpectation, userFolderExpectation]

        var cancellable = Set<AnyCancellable>()

        // WHEN
        let folderListViewModel = FolderListViewModel(mailboxManager: mailboxManager)

        // THEN
        folderListViewModel.$roleFolders.dropFirst().sink {
            roleFolderExpectation.fulfill()
            XCTAssertGreaterThan($0.count, 0, "Expecting a non empty array")
            print("roleFolders updated, count: \($0.count)")
        }.store(in: &cancellable)
        folderListViewModel.$userFolders.dropFirst().sink {
            userFolderExpectation.fulfill()
            XCTAssertGreaterThan($0.count, 0, "Expecting a non empty array")
            print("userFolders updated, count: \($0.count)")
        }.store(in: &cancellable)

        wait(for: asyncExpectations, timeout: 10.0)
        XCTAssertGreaterThan(folderGenerator.foldersWithRole.count, 0)
        XCTAssertGreaterThan(folderGenerator.folders.count, 0)
        XCTAssertEqual(folderListViewModel.roleFolders.count, folderGenerator.foldersWithRole.count)
        XCTAssertEqual(folderListViewModel.userFolders.count, folderGenerator.folders.count)
    }
}
