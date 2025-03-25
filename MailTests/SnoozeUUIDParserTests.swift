/*
 Infomaniak Mail - iOS App
 Copyright (C) 2025 Infomaniak Network SA

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

@testable import MailCore
import XCTest

final class SnoozeUUIDParserTests: XCTestCase {
    func testValidUUIDFromSimpleString() {
        let lowercaseUUID = "123e4567-e89b-12d3-a456-426655440000"
        let uppercaseUUID = "123E4567-E89B-12D3-A456-426655440000"

        let parser = SnoozeUUIDParser()

        let inputs = [lowercaseUUID, uppercaseUUID]
        for input in inputs {
            let result = parser.parse(resource: input)
            XCTAssertEqual(result, input)
        }
    }

    func testInvalidUUIDFromSimpleString() {
        let lowercaseUUID = "123e4567-e89b-12d3-z456-426655440000"
        let uppercaseUUID = "123E4567-E89B-12D3-Z456-426655440000"

        let parser = SnoozeUUIDParser()

        let inputs = [lowercaseUUID, uppercaseUUID]
        for input in inputs {
            let result = parser.parse(resource: input)
            XCTAssertEqual(result, nil)
        }
    }

    func testExtractUUIDFromActualResource() {
        let dataSet: [(input: String, output: String)] = [
            (
                "/api/mail/c33185f8-63b3-346d-a14e-cd84dbb46294/snoozes/9e82f294-42f6-4276-8486-da6f2f6cda73",
                "9e82f294-42f6-4276-8486-da6f2f6cda73"
            ),
            (
                "/api/mail/c34275f7-64c2-347c-a23e-ce84dbb44294/snoozes/9e82f294-47e0-43f0-947c-776d90329967",
                "9e82f294-47e0-43f0-947c-776d90329967"
            )
        ]

        let parser = SnoozeUUIDParser()
        for data in dataSet {
            let result = parser.parse(resource: data.input)
            XCTAssertEqual(result, data.output)
        }
    }

    func testExtractUUIDFromTransformedResource() {
        let dataSet: [(input: String, output: String)] = [
            (
                "/api/mail/c33185f7-31b1-264c-b14e-cd84dbb46294/snoozed/9e82f294-42f6-4276-8486-da6f2f6cda73/add",
                "9e82f294-42f6-4276-8486-da6f2f6cda73"
            ),
            (
                "/api/mail/add-snooze/9e82f294-47e0-43f0-947c-776d90329967",
                "9e82f294-47e0-43f0-947c-776d90329967"
            )
        ]

        let parser = SnoozeUUIDParser()
        for data in dataSet {
            let result = parser.parse(resource: data.input)
            XCTAssertEqual(result, data.output)
        }
    }
}
