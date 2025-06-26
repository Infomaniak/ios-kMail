/*
 Infomaniak Mail - iOS App
 Copyright (C) 2022 Infomaniak Network SA

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import Combine
import Foundation
@testable import Infomaniak_Mail
import InfomaniakCore
import InfomaniakCoreDB
import InfomaniakLogin
@testable import MailCore
@testable import RealmSwift
import XCTest

struct MCKContactManageable_FolderListViewModel: ContactManageable, MCKTransactionablePassthrough {
    var realmConfiguration: RealmSwift.Realm.Configuration {
        fatalError("Unexpected")
    }

    let transactionExecutor: Transactionable!

    func frozenContacts(matching string: String, fetchLimit: Int?,
                        sorted: ((MergedContact, MergedContact) -> Bool)?) -> any Collection<MailCore.MergedContact> { [] }

    func frozenContactsAsync(matching string: String, fetchLimit: Int?,
                             sorted: ((MailCore.MergedContact, MailCore.MergedContact) -> Bool)?) async
        -> any Collection<MailCore.MergedContact> { [] }

    func getContact(for correspondent: any MailCore.Correspondent) -> MailCore.MergedContact? { nil }

    func getContact(for correspondent: any Correspondent, transactionable: Transactionable) -> MergedContact? { nil }

    func frozenGroupContacts(matching string: String, fetchLimit: Int?) -> any Collection<MailCore.GroupContact> { [] }

    func frozenAddressBookContacts(matching string: String, fetchLimit: Int?) -> any Collection<MailCore.AddressBook> { [] }

    func getContacts(with groupContactId: Int) -> [MailCore.MergedContact] { [] }

    func getContacts(for addressBookId: Int) -> [MailCore.MergedContact] { [] }

    func addressBook(with id: Int) -> MailCore.AddressBook? { nil }

    func addContact(recipient: MailCore.Recipient) async throws {}

    func getFrozenAddressBook(for groupContactId: Int) async -> MailCore.AddressBook? { nil }

    func refreshContactsAndAddressBooksIfNeeded() async throws {}

    func refreshContactsAndAddressBooks() async throws {}

    static func deleteUserContacts(userId: Int) {}
}

/// A MailboxManageable used to test the FolderListViewModel
struct MCKMailboxManageable_FolderListViewModel: MailboxManageable, MCKTransactionablePassthrough {
    let mailbox = Mailbox()

    var contactManager: MailCore.ContactManageable {
        MCKContactManageable_FolderListViewModel(transactionExecutor: transactionExecutor)
    }

    func refreshAllFolders() async throws {}

    func deleteFolder(folder: MailCore.Folder) async throws {}

    func getFolder(with role: MailCore.FolderRole) -> MailCore.Folder? {
        fatalError("Unexpected")
    }

    func createFolder(name: String, parent: MailCore.Folder?) async throws -> MailCore.Folder {
        fatalError("Unexpected")
    }

    func modifyFolder(name: String, folder: MailCore.Folder) async throws {
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

    var transactionExecutor: Transactionable!
    init(transactionExecutor: Transactionable) {
        self.transactionExecutor = transactionExecutor
    }

    func draftWithPendingAction() -> RealmSwift.Results<MailCore.Draft> {
        fatalError("Unexpected")
    }

    func send(draft: MailCore.Draft) async throws -> MailCore.SendResponse {
        fatalError("Unexpected")
    }

    func save(draft: MailCore.Draft) async throws {}

    func delete(draft: MailCore.Draft) async throws {}

    func delete(messages: [MailCore.Message]) async throws {}

    func deleteLocally(draft: MailCore.Draft) async throws {}

    func deleteLocally(drafts: [MailCore.Draft]) async throws {}

    func deleteOrphanDrafts() async {}

    func messages(folder: MailCore.Folder) async throws {}

    func fetchOneOldPage(folder: MailCore.Folder) async throws -> Int? { nil }

    func message(message: MailCore.Message) async throws {}

    func attachmentData(_ attachment: MailCore.Attachment, progressObserver: ((Double) -> Void)?) async throws -> Data { Data() }

    func saveAttachmentLocally(attachment: MailCore.Attachment, progressObserver: ((Double) -> Void)?) async {}

    func markAsSeen(message: MailCore.Message, seen: Bool) async throws {}

    func move(messages: [MailCore.Message], to folderRole: MailCore.FolderRole, origin: Folder?) async throws -> MailCore
        .UndoAction {
        fatalError("Unexpected")
    }

    func move(messages: [MailCore.Message], to folder: MailCore.Folder, origin: Folder?) async throws -> MailCore.UndoAction {
        fatalError("Unexpected")
    }

    func delete(draftMessages: [MailCore.Message]) async throws {}

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
        fatalError("Unexpected")
    }

    func draft(messageUid: String) -> MailCore.Draft? { nil }

    func draft(messageUid: String, using realm: RealmSwift.Realm) -> MailCore.Draft? { nil }

    func draft(localUuid: String) -> MailCore.Draft? { nil }

    func draft(localUuid: String, using realm: RealmSwift.Realm) -> MailCore.Draft? { nil }

    func draft(remoteUuid: String) -> MailCore.Draft? { nil }

    func draft(remoteUuid: String, using realm: RealmSwift.Realm) -> MailCore.Draft? { nil }

    func getFrozenFolders() -> [MailCore.Folder] { [] }

    func swissTransferAttachment(message: MailCore.Message) async throws {
        fatalError("Unexpected")
    }
}

/// Integration tests of the FolderListViewModel
final class ITFolderListViewModel: XCTestCase {
    override static func setUp() {
        super.setUp()

        MockingHelper.clearRegisteredTypes()
        MockingHelper.registerConcreteTypes(configuration: .realApp)
    }

    @MainActor func testInitAndFetchFromDB() throws {
        // GIVEN
        let folderGenerator = FolderStructureGenerator(maxDepth: 5, maxElementsPerLevel: 5)

        let folderRealmResults = folderGenerator.transactionable.fetchResults(ofType: Folder.self) { partial in
            partial
        }.freezeIfNeeded()

        let mailboxManager = MCKMailboxManageable_FolderListViewModel(transactionExecutor: folderGenerator.transactionable)

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

        wait(for: asyncExpectations, timeout: 20.0)

        XCTAssertGreaterThan(folderGenerator.frozenFoldersWithRole.count, 0)
        XCTAssertGreaterThan(folderGenerator.frozenFolders.count, 0)

        let roleFoldersMap = folderListViewModel.roleFolders.compactMap(\.frozenContent.role)

        for folderRole in folderGenerator.mandatoryFolderRoles {
            XCTAssertTrue(roleFoldersMap.contains(folderRole), "\(folderRole) not found")
        }

        XCTAssertEqual(folderListViewModel.userFolders.count, folderGenerator.frozenFolders.count)
    }
}

/// Integration tests of the FolderListViewModelWorker
final class ITFolderListViewModelWorker: XCTestCase {
    override static func setUp() {
        super.setUp()

        MockingHelper.clearRegisteredTypes()
        MockingHelper.registerConcreteTypes(configuration: .realApp)
    }

    func testFilterAndSortFolders_noSearch() async throws {
        // GIVEN
        let folderGenerator = FolderStructureGenerator(maxDepth: 5, maxElementsPerLevel: 5)
        let folderRealmResults = folderGenerator.transactionable.fetchResults(ofType: Folder.self) { partial in
            partial
        }.freezeIfNeeded()

        let expectedFrozenFolders = folderGenerator.frozenFolders.map { $0.freeze() }

        let worker = FolderListViewModelWorker()

        // WHEN
        let result = await worker.filterAndSortFolders(folderRealmResults, searchQuery: "")

        // THEN
        let resultFolderRoles = result.roleFolders.compactMap(\.frozenContent.role)

        for folderRole in folderGenerator.mandatoryFolderRoles {
            XCTAssertTrue(resultFolderRoles.contains(folderRole), "\(folderRole) not found")
        }
        XCTAssertEqual(result.userFolders.count, expectedFrozenFolders.count)
    }

    func testFilterAndSortFolders_SearchRandomElement() async throws {
        // GIVEN
        let folderGenerator = FolderStructureGenerator(maxDepth: 5, maxElementsPerLevel: 5)
        let folderRealmResults = folderGenerator.transactionable.fetchResults(ofType: Folder.self) { partial in
            partial
        }.freezeIfNeeded()
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

        XCTAssertTrue(
            allFolders.contains { $0.frozenContent.id == randomFolder.id },
            "We expect the results to contain the folder"
        )
    }

    func testFilterAndSortFolders_SearchNoMatch() async throws {
        // GIVEN
        let searchString = "nope"
        let folderGenerator = FolderStructureGenerator(maxDepth: 5, maxElementsPerLevel: 5)
        let folderRealmResults = folderGenerator.transactionable.fetchResults(ofType: Folder.self) { partial in
            partial
        }.freezeIfNeeded()
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
