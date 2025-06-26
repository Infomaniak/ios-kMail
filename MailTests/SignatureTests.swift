/*
 Infomaniak Mail - iOS App
 Copyright (C) 2023 Infomaniak Network SA

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

import InfomaniakCore
import InfomaniakLogin
@testable import MailCore
import SwiftSoup
import XCTest

final class SignatureTests: XCTestCase {
    /// Some random HTML content
    static let someMailContent = "<br><br><h1>Hello<h1></br></br>"

    /// A basic signature wrapped in the "editorUserSignature" class
    static let basicSignature =
        "<br><br><div class=\"editorUserSignature\"><p>test signature absolute bottom<br></p></div>"

    override static func setUp() {
        super.setUp()

        MockingHelper.clearRegisteredTypes()
        MockingHelper.registerConcreteTypes(configuration: .minimal)
    }

    // MARK: - Signature apending

    func testAppendSignatureAfter() {
        // GIVEN
        let mckSignature = Signature()
        mckSignature.content = Self.basicSignature
        mckSignature.position = .afterReplyMessage

        // WHEN
        let newBody = mckSignature.appendSignature(to: Self.someMailContent)

        // THEN
        XCTAssertTrue(!newBody.isEmpty, "we should have some content")

        do {
            let document = try SwiftSoup.parse(newBody)
            guard let signatureNode = try document.getElementsByClass(Constants.signatureHTMLClass).first() else {
                XCTFail("Unexpected signature not found")
                return
            }
            XCTAssertTrue(try (signatureNode.text().count) > 0, "We expect a non empty signature content")
        } catch {
            XCTFail("Unexpected :\(error)")
        }
    }

    func testAppendSignatureBefore() {
        // GIVEN
        let mckSignature = Signature()
        mckSignature.content = Self.basicSignature
        mckSignature.position = .beforeReplyMessage

        // WHEN
        let newBody = mckSignature.appendSignature(to: Self.someMailContent)

        // THEN
        XCTAssertTrue(!newBody.isEmpty, "we should have some content")

        do {
            let document = try SwiftSoup.parse(newBody)
            guard let signatureNode = try document.getElementsByClass(Constants.signatureHTMLClass).first() else {
                XCTFail("Unexpected signature not found")
                return
            }
            XCTAssertTrue(try (signatureNode.text().count) > 0, "We expect a non empty signature content")
        } catch {
            XCTFail("Unexpected :\(error)")
        }
    }
}
