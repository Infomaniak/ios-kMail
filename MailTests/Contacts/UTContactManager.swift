/*
 Infomaniak Mail - iOS App
 Copyright (C) 2024 Infomaniak Network SA

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
import XCTest

final class UTContactManager: XCTestCase {
    let contactManager = ContactManager(userId: 0, apiFetcher: MailApiFetcher())

    override func setUpWithError() throws {}

    func generateFakeContacts(count: Int) {
        do {
            try contactManager.writeTransaction { writableRealm in
                writableRealm.deleteAll()
            }

            try contactManager.writeTransaction { writableRealm in
                for i in 0 ..< count {
                    let contact = MergedContact()
                    contact.id = "\(i)"
                    let randomName = UUID().uuidString
                    contact.name = "\(randomName)"
                    contact.email = "\(randomName)@somemail.com"
                    writableRealm.add(contact)
                }
            }
        } catch {
            fatalError("failed transaction in base, error:\(error)")
        }
    }

    func testGetContactsMatching() throws {
        // GIVEN
        generateFakeContacts(count: 100_000)
        measure {
            // WHEN
            let matchingContacts = contactManager.frozenContacts(matching: "mail", fetchLimit: nil)
            // THEN
            XCTAssertEqual(matchingContacts.isEmpty, false)
        }
    }
}
