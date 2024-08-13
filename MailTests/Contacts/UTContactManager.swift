/*
 Infomaniak Mail - iOS App
 Copyright (C) 2024 Infomaniak Network SA

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

import MailCore
import XCTest

final class UTContactManager: XCTestCase {
    let contactManager = ContactManager(userId: 0, apiFetcher: MailApiFetcher())

    override class func setUp() {
        super.setUp()

        MockingHelper.clearRegisteredTypes()
        MockingHelper.registerConcreteTypes(configuration: .minimal)
    }

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

    @discardableResult
    func generateMergedContact(name: String, email: String) -> MergedContact {
        do {
            let contact = MergedContact()
            contact.id = UUID().uuidString
            contact.name = name
            contact.email = email

            try contactManager.writeTransaction { writableRealm in
                writableRealm.add(contact)
            }

            return contact
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

    func testGetContactFirstName() throws {
        // GIVEN
        generateMergedContact(name: "Some Person", email: "samemail@mail.com")
        generateMergedContact(name: "Some Other", email: "samemail@mail.com")
        generateMergedContact(name: "Dr. Some Other", email: "samemail@mail.com")

        let recipient0 = Recipient(email: "someother@mail.com", name: "Some Person")
        let recipient1 = Recipient(email: "samemail@mail.com", name: "Some Person")
        let recipient2 = Recipient(email: "samemail@mail.com", name: "Some Other")
        let recipient3 = Recipient(email: "samemail@mail.com", name: "Dr. Some Other")
        let recipient4 = Recipient(email: "samemail@mail.com", name: "Dr Some Other")
        let recipient5 = Recipient(email: "samemail@mail.com", name: "dr. some other")

        // WHEN
        let merged0 = contactManager.getContact(for: recipient0)
        let merged1 = contactManager.getContact(for: recipient1)
        let merged2 = contactManager.getContact(for: recipient2)
        let merged3 = contactManager.getContact(for: recipient3)
        let merged4 = contactManager.getContact(for: recipient4)
        let merged5 = contactManager.getContact(for: recipient5)

        // THEN
        XCTAssertNil(merged0, "We only match on email address")
        XCTAssertEqual(recipient1.name, merged1?.name)
        XCTAssertEqual(recipient2.name, merged2?.name)
        XCTAssertEqual(recipient3.name, merged3?.name, "We only want perfect matches case insensitive but diatric sensistive")
        XCTAssertNotEqual(recipient4.name, merged4?.name, "We only want perfect matches case insensitive but diatric sensistive")
        XCTAssertTrue(
            merged5?.name.caseInsensitiveCompare(recipient5.name) == .orderedSame,
            "We only want perfect matches case insensitive but diatric sensistive"
        )
    }
}
