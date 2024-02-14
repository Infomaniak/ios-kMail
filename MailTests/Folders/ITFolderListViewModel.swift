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
@testable import Infomaniak_Mail
import InfomaniakCore
import InfomaniakLogin
@testable import MailCore
@testable import RealmSwift
import XCTest

struct MCKContactManageable_FolderListViewModel: ContactManageable {
    func frozenContacts(matching string: String, fetchLimit: Int?) -> any Collection<MailCore.MergedContact> { [] }

    func getContact(for correspondent: any MailCore.Correspondent, realm: RealmSwift.Realm?) -> MailCore.MergedContact? { nil }

    func addressBook(with id: Int) -> MailCore.AddressBook? { nil }

    func addContact(recipient: MailCore.Recipient) async throws {}

    func refreshContactsAndAddressBooks() async throws {}

    static func deleteUserContacts(userId: Int) {}

    var realmConfiguration: RealmSwift.Realm.Configuration
}

/// A MailboxManageable used to test the FolderListViewModel
struct MCKMailboxManageable_FolderListViewModel: MailboxManageable {
    let mailbox = Mailbox()

    var contactManager: MailCore.ContactManageable {
        MCKContactManageable_FolderListViewModel(realmConfiguration: realmConfiguration)
    }

    func refreshAllFolders() async throws {}

    func getFrozenFolders(with role: MailCore.FolderRole) -> MailCore.Folder? {
        fatalError("Unexpected")
    }

    func getFrozenFolders(using realm: RealmSwift.Realm?) -> [MailCore.Folder] {
        fatalError("Unexpected")
    }

    func getFolders(using realm: RealmSwift.Realm?) -> [MailCore.Folder] {
        fatalError("Unexpected")
    }

    func getFolder(with role: MailCore.FolderRole) -> MailCore.Folder? {
        fatalError("Unexpected")
    }

    func createFolder(name: String, parent: MailCore.Folder?) async throws -> MailCore.Folder {
        fatalError("Unexpected")
    }

    func flushFolder(folder: MailCore.Folder) async throws -> Bool { false }

    func refreshFolder(from messages: [MailCore.Message], additionalFolder: MailCore.Folder?) async throws {}

    func refreshFolderContent(_ folder: MailCore.Folder) async {}

    func cancelRefresh() async {}

    func initSearchFolder() -> MailCore.Folder {
        fatalError("Unexpected")
    }

    func clearSearchResults() async {}

    func searchThreads(
        searchFolder: MailCore.Folder?,
        filterFolderId: String,
        filter: MailCore.Filter,
        searchFilter: [URLQueryItem]
    ) async throws -> MailCore.ThreadResult {
        fatalError("Unexpected")
    }

    func searchThreads(searchFolder: MailCore.Folder?, from resource: String,
                       searchFilter: [URLQueryItem]) async throws -> MailCore.ThreadResult {
        fatalError("Unexpected")
    }

    func searchThreadsOffline(
        searchFolder: MailCore.Folder?,
        filterFolderId: String,
        searchFilters: [MailCore.SearchCondition]
    ) async {}

    func addToSearchHistory(value: String) async {}

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

    func calendarEvent(from messageUid: String) async throws {
        fatalError("Unexpected")
    }

    func replyToCalendarEvent(messageUid: String, reply: MailCore.AttendeeState) async throws {
        fatalError("Unexpected")
    }

    func importICSEventToCalendar(messageUid: String) async throws -> MailCore.CalendarEvent {
        fatalError("Unexpected")
    }

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

        let mailboxManager = MCKMailboxManageable_FolderListViewModel(realm: folderGenerator.inMemoryRealm)

        let roleFolderExpectation = XCTestExpectation(description: "[roleFolders] should be updated.")
        let userFolderExpectation = XCTestExpectation(description: "[userFolders] should be updated.")
        let viewModelExpectation = XCTestExpectation(description: "folderListViewModel should be updated twice.")
        viewModelExpectation.expectedFulfillmentCount = 2
        let asyncExpectations = [roleFolderExpectation, userFolderExpectation, viewModelExpectation]

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
        folderListViewModel.objectWillChange.dropFirst().sink {
            viewModelExpectation.fulfill()
            print("ViewModel updated")
        }.store(in: &cancellable)

        wait(for: asyncExpectations, timeout: 10.0)
        XCTAssertGreaterThan(folderGenerator.foldersWithRole.count, 0)
        XCTAssertGreaterThan(folderGenerator.folders.count, 0)
        XCTAssertEqual(folderListViewModel.roleFolders.count, folderGenerator.foldersWithRole.count)
        XCTAssertEqual(folderListViewModel.userFolders.count, folderGenerator.folders.count)
    }
}

/// Integration tests of the FolderListViewModelWorker
final class ITFolderListViewModelWorker: XCTestCase {
    func testFilterAndSortFolders_noSearch() async {
        // GIVEN
        let folderGenerator = FolderStructureGenerator(maxDepth: 5, maxElementsPerLevel: 5)
        let folderRealmResults = folderGenerator.inMemoryRealm.objects(Folder.self).freezeIfNeeded()
        print("generated \(folderRealmResults.count) folders")

        let worker = FolderListViewModelWorker()

        // WHEN
        let result = await worker.filterAndSortFolders(folderRealmResults, searchQuery: "")

        // THEN
        XCTAssertGreaterThan(folderGenerator.foldersWithRole.count, 0)
        XCTAssertGreaterThan(folderGenerator.folders.count, 0)
        XCTAssertEqual(result.roleFolders.count, folderGenerator.foldersWithRole.count)
        XCTAssertEqual(result.userFolders.count, folderGenerator.folders.count)
    }

    func testFilterAndSortFolders_SearchRandomElement() async {
        // GIVEN
        let folderGenerator = FolderStructureGenerator(maxDepth: 5, maxElementsPerLevel: 5)
        let folderRealmResults = folderGenerator.inMemoryRealm.objects(Folder.self).freezeIfNeeded()
        guard let randomFolder = folderRealmResults.randomElement() else {
            XCTFail("Unexpected")
            return
        }
        print("generated \(folderRealmResults.count) folders")

        let worker = FolderListViewModelWorker()

        // WHEN
        let result = await worker.filterAndSortFolders(folderRealmResults, searchQuery: randomFolder.localizedName)
        let allFolders = result.roleFolders + result.userFolders

        // THEN
        XCTAssertGreaterThanOrEqual(allFolders.count, 1, "There should be at least one match")
        guard let matchingFolder = allFolders.first else {
            XCTFail("Unexpected")
            return
        }
        XCTAssertEqual(matchingFolder.frozenContent.localizedName, randomFolder.localizedName, "We expect the names to match")
    }

    func testFilterAndSortFolders_SearchNoMatch() async {
        // GIVEN
        let searchString = "nope"
        let folderGenerator = FolderStructureGenerator(maxDepth: 5, maxElementsPerLevel: 5)
        let folderRealmResults = folderGenerator.inMemoryRealm.objects(Folder.self).freezeIfNeeded()
        print("generated \(folderRealmResults.count) folders")

        XCTAssertFalse(FolderStructureGenerator.wordDictionary.contains(searchString), "We should not have a match")

        let worker = FolderListViewModelWorker()

        // WHEN
        let result = await worker.filterAndSortFolders(folderRealmResults, searchQuery: searchString)
        let allFolders = result.roleFolders + result.userFolders

        // THEN
        XCTAssertEqual(allFolders.count, 0, "There should be no match")
    }
}
