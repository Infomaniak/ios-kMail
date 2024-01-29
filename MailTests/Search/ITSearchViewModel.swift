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
import InfomaniakCore
import InfomaniakLogin
@testable import Mail
@testable import MailCore
import RealmSwift
import XCTest

// MARK: - Mocking

/// A ContactManageable used to test the SearchViewModel
struct MCKContactManageable_SearchViewModel: ContactManageable {
    func contacts(matching string: String, fetchLimit: Int?) -> [MailCore.MergedContact] { [] }

    func getContact(for recipient: MailCore.Recipient, realm: RealmSwift.Realm?) -> MailCore.MergedContact? { nil }

    func addressBook(with id: Int) -> MailCore.AddressBook? { nil }

    func addContact(recipient: MailCore.Recipient) async throws {}

    func refreshContactsAndAddressBooks() async throws {}

    static func deleteUserContacts(userId: Int) {}

    var realmConfiguration: RealmSwift.Realm.Configuration
}

/// A MailboxManageable used to test the SearchViewModel
final class MCKMailboxManageable_SearchViewModel: MailboxManageable {
    let targetFolder: Folder
    let realm: Realm
    let folderGenerator: FolderStructureGenerator
    init(realm: Realm, targetFolder: Folder, folderGenerator: FolderStructureGenerator) {
        self.realm = realm
        self.targetFolder = targetFolder
        self.folderGenerator = folderGenerator
    }

    var contactManager: MailCore.ContactManageable {
        MCKContactManageable_FolderListViewModel(realmConfiguration: realmConfiguration)
    }

    func refreshAllFolders() async throws {}

    func getFolder(with role: MailCore.FolderRole) -> MailCore.Folder? {
        folderGenerator.foldersWithRole.first { folder in
            guard let folderRole = folder.role else {
                return false
            }

            return folderRole == role
        }
    }

    func getFolders(using realm: RealmSwift.Realm?) -> [MailCore.Folder] {
        folderGenerator.folders
    }

    func createFolder(name: String, parent: MailCore.Folder?) async throws -> MailCore.Folder {
        fatalError("Unexpected")
    }

    func flushFolder(folder: MailCore.Folder) async throws -> Bool { false }

    func refreshFolder(from messages: [MailCore.Message], additionalFolder: MailCore.Folder?) async throws {}

    func refreshFolderContent(_ folder: MailCore.Folder) async {}

    func cancelRefresh() async {}

    func initSearchFolder() -> MailCore.Folder { targetFolder }

    // MARK: searchThreads

    var searchThreadsCallCount = 0
    var searchThreadsReceivedFolder: MailCore.Folder?
    var searchThreadsReceivedFilterFolderId: String?
    var searchThreadsReceivedFilter: MailCore.Filter?
    var searchThreadsReceivedSearchFilter: [URLQueryItem]?
    var searchThreadsReturnValue = ThreadResult(
        threads: nil,
        totalMessagesCount: 0,
        messagesCount: 0,
        currentOffset: 0,
        threadMode: "",
        folderUnseenMessages: 0,
        resourcePrevious: nil,
        resourceNext: nil
    )
    func searchThreads(
        searchFolder: MailCore.Folder?,
        filterFolderId: String,
        filter: MailCore.Filter,
        searchFilter: [URLQueryItem]
    ) async throws -> MailCore.ThreadResult {
        searchThreadsCallCount += 1
        searchThreadsReceivedFolder = searchFolder
        searchThreadsReceivedFilterFolderId = filterFolderId
        searchThreadsReceivedFilter = filter
        searchThreadsReceivedSearchFilter = searchFilter

        return searchThreadsReturnValue
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

// MARK: - ITSearchViewModel

final class ITSearchViewModel: XCTestCase {
    @MainActor func testInit() {
        // GIVEN
        let folderGenerator = FolderStructureGenerator(maxDepth: 5, maxElementsPerLevel: 5)
        guard let someFolder = folderGenerator.folders.first else {
            XCTFail("Unexpected")
            return
        }

        let mailboxManager = MCKMailboxManageable_SearchViewModel(
            realm: folderGenerator.inMemoryRealm,
            targetFolder: someFolder,
            folderGenerator: folderGenerator
        )

        let realFolderExpectation = XCTestExpectation(description: "realFolder should be updated.")
        let folderListExpectation = XCTestExpectation(description: "folderList should be updated.")

        let asyncExpectations = [realFolderExpectation, folderListExpectation]
        var cancellable = Set<AnyCancellable>()

        // WHEN
        let viewModel = SearchViewModel(mailboxManager: mailboxManager, folder: someFolder)

        // THEN
        viewModel.$realFolder.sink { folder in
            realFolderExpectation.fulfill()
            XCTAssertNotNil(folder)
            XCTAssertTrue(folder.isFrozen)
            XCTAssertEqual(folder.remoteId, someFolder.remoteId)
        }.store(in: &cancellable)
        viewModel.$folderList.sink { folderList in
            XCTAssertNotNil(folderList)
            XCTAssertEqual(folderList, folderGenerator.folders)
            folderListExpectation.fulfill()
        }.store(in: &cancellable)

        wait(for: asyncExpectations, timeout: 10.0)
    }

    @MainActor func testSearch() {
        // GIVEN
        let folderGenerator = FolderStructureGenerator(maxDepth: 5, maxElementsPerLevel: 5)
        guard let someFolder = folderGenerator.folders.first else {
            XCTFail("Unexpected")
            return
        }

        guard let searchWord = FolderStructureGenerator.wordDictionary.randomElement() else {
            XCTFail("Unexpected")
            return
        }

        let expectedSearchFilter = [URLQueryItem(name: "scontains", value: searchWord),
                                    URLQueryItem(name: "severywhere", value: "1")]

        let mailboxManager = MCKMailboxManageable_SearchViewModel(
            realm: folderGenerator.inMemoryRealm,
            targetFolder: someFolder,
            folderGenerator: folderGenerator
        )

        let contactsExpectation = XCTestExpectation(description: "contacts should be updated.")
        let threadExpectation = XCTestExpectation(description: "threads should be updated.")
        let isLoadingExpectation = XCTestExpectation(description: "isLoading should be updated.")
        let viewModelExpectation = XCTestExpectation(description: "folderListViewModel should be updated multiple times.")
        viewModelExpectation.expectedFulfillmentCount = 4

        let asyncExpectations = [contactsExpectation, threadExpectation, viewModelExpectation]
        var cancellable = Set<AnyCancellable>()

        let viewModel = SearchViewModel(mailboxManager: mailboxManager, folder: someFolder)

        // WHEN
        viewModel.searchValue = searchWord

        // THEN
        viewModel.$realFolder.dropFirst().sink { _ in
            XCTFail("realFolder should not change")
        }.store(in: &cancellable)
        viewModel.$folderList.dropFirst().sink { _ in
            XCTFail("folderList should not change")
        }.store(in: &cancellable)

        viewModel.$threads.dropFirst().sink { _ in
            threadExpectation.fulfill()
        }.store(in: &cancellable)
        viewModel.$contacts.sink { _ in
            contactsExpectation.fulfill()
        }.store(in: &cancellable)
        viewModel.$isLoading.dropFirst().sink { _ in
            isLoadingExpectation.fulfill()
        }.store(in: &cancellable)

        viewModel.objectWillChange.dropFirst().sink {
            viewModelExpectation.fulfill()
        }.store(in: &cancellable)

        wait(for: asyncExpectations, timeout: 10.0)
        XCTAssertEqual(viewModel.lastSearch, searchWord, "The search string should be updated")
        XCTAssertEqual(viewModel.searchValueType, .threadsAndContacts)

        // Check the search parameters received by the mailboxManager
        XCTAssertEqual(mailboxManager.searchThreadsCallCount, 1)
        XCTAssertEqual(mailboxManager.searchThreadsReceivedFilter, .all)
        XCTAssertEqual(mailboxManager.searchThreadsReceivedFolder?.remoteId, someFolder.remoteId)
        XCTAssertEqual(mailboxManager.searchThreadsReceivedFilterFolderId, someFolder.remoteId)
        XCTAssertEqual(mailboxManager.searchThreadsReceivedSearchFilter, expectedSearchFilter)
    }
}
