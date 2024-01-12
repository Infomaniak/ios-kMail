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
import InfomaniakCore
import InfomaniakLogin
@testable import Mail
@testable import MailCore
@testable import RealmSwift
import XCTest

/// Integration tests of the FolderListViewModel
final class ITFolderListViewModel: XCTestCase {
    // MARK: - Test roleFolders

    func testRoleFolders() {
        // TODO: fixme
    }

    // MARK: - Test userFolders

    func testUserAndRoleFolderFiltering() {
        // GIVEN
        let apiToken = ApiToken(accessToken: "accessToken",
                                expiresIn: .max,
                                refreshToken: "refreshToken",
                                scope: "scope",
                                tokenType: "tokenType",
                                userId: 42,
                                expirationDate: Date().addingTimeInterval(Date().timeIntervalSince1970))

        let mailApiFetcher = MailApiFetcher()
        let mailboxManager = MailboxManager(account: Account(apiToken: apiToken),
                                            mailbox: Mailbox(),
                                            apiFetcher: mailApiFetcher,
                                            contactManager: ContactManager(userId: 42, apiFetcher: mailApiFetcher))
        let folderListViewModel = FolderListViewModel(mailboxManager: mailboxManager)
        let folderGenerator = FolderStructureGenerator(maxDepth: 5, maxElementsPerLevel: 5)
        let folderRealmResults = folderGenerator.inMemoryRealm.objects(Folder.self).freezeIfNeeded()
        print("generated \(folderRealmResults.count) folders")

        // TODO: test events
//        let roleFolderExpectation = XCTestExpectation(description: "[roleFolders] should be updated.")
//        roleFolderExpectation.expectedFulfillmentCount = 2
//
//        let userFolderExpectation = XCTestExpectation(description: "[userFolders] should be updated.")
//        userFolderExpectation.expectedFulfillmentCount = 2
//
//        let viewModelExpectation = XCTestExpectation(description: "folderListViewModel should be updated.")
//        let asyncExpectations = [roleFolderExpectation, userFolderExpectation /* , viewModelExpectation */ ]
//
//        folderListViewModel.$roleFolders.sink(receiveValue: {
//            roleFolderExpectation.fulfill()
//            print("roleFolders updated, new value: \($0)")
//        })
//        folderListViewModel.$userFolders.sink(receiveValue: {
//            userFolderExpectation.fulfill()
//            print("userFolders updated, new value: \($0)")
//        })
//        folderListViewModel.objectWillChange.sink(receiveValue: {
//            viewModelExpectation.fulfill()
//            print("ViewModel updated: \($0)")
//        })

        // WHEN
        folderListViewModel.filterAndSortFolders(folderRealmResults)

        // THEN
        // wait(for: asyncExpectations, timeout: 10.0)
        XCTAssertNotEqual(folderGenerator.foldersWithRole.count, 0)
        XCTAssertNotEqual(folderGenerator.folders.count, 0)
        XCTAssertEqual(folderListViewModel.roleFolders.count, folderGenerator.foldersWithRole.count)
        XCTAssertEqual(folderListViewModel.userFolders.count, folderGenerator.folders.count)
    }
}
