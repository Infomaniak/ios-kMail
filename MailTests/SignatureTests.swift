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

import InfomaniakCore
import InfomaniakLogin
@testable import MailCore
import XCTest

final class SignatureTests: XCTestCase {
    static let basicSignature = "<p>test signature absolute bottom<br></p>"
    static let basicSignatureWrapped =
        "<br><br><div class=\"editorUserSignature\"><p>test signature absolute bottom<br></p></div>"

    /// A JS script modify the body of the mail, but it is still empty
    static let domBodyWithbasicSignature =
        "<div><br></div><div><br></div><div class=\"editorUserSignature\"><p>test signature absolute bottom<br></p></div><div><br></div>"

    static let htmlSignature =
        "<br><br><div class=\"editorUserSignature\"><div style=\"width: 100%;\"><div style=\"float: left; margin-right: 20px;\"><div style=\"background-color: #0098ff; width: 45px; height: 45px; text-align: center; line-height: 45px; font-family: Arial; color: #ffffff; border-radius: 4px; font-size: 26px;\"><b>k</b><br></div></div><div style=\"margin-left: 65px;\"><h1 style=\"font-family: Arial; font-size: 22px; color: #0098ff; line-height: 22px; margin-bottom: 7px;\"><b>infomaniak</b><br></h1><p style=\"font-family: Arial; font-size: 15px; color: #666666; margin: 0;\">  Developer<br></p><div style=\"margin: 15px 0px 15px 0px; height: 1px; color: #ebebeb; background-color: #e0e0e0; border: none;\" width=\"400px\"><br></div><div style=\"font-family: Arial; font-size: 12px; color: #666666; margin-bottom: 7px;\">Rue Eugène-Marziano 25, 1227 Genève<br></div><div><span style=\"color: rgb(212, 68, 68);\"><b><span class=\"font\" style=\"font-family:Arial\"><span class=\"size\" style=\"font-size:12px\">Swiss Made</span></span></b></span><span style=\"color: #e0e0e0;\">&nbsp;|&nbsp;</span><span style=\"color: rgb(102, 102, 102);\"><span class=\"font\" style=\"font-family:Arial\"><span class=\"size\" style=\"font-size:12px\">ISO 27001 14001 50001 9001</span></span></span><br></div></div></div><p><br></p></div>"

    // TODO: test signature apending

//    func testAppendSignatureAfter() {
//        // GIVEN
//        let mckSignature = Signature()
//        mckSignature.content = Self.basicSignature
//        mckSignature.position = .afterReplyMessage
//
//        // WHEN
//        // I add a signature
//        let newBody = mckSignature.appendSignature(to: "")
//        XCTAssertEqual(newBody, "")
//    }
//
//    func testAppendSignatureAfter() {
//        // GIVEN
//        let mckSignature = Signature()
//        mckSignature.content = Self.basicSignature
//        mckSignature.position = .beforeReplyMessage
//
//        // WHEN
//        // I add a signature
//        let newBody = mckSignature.appendSignature(to: "")
//        XCTAssertEqual(newBody, "")
//    }

    // TODO: test signature removal

    // TODO: test empty body detection

    // This does _not_ pass, it is a bug to fix
    func testEmptyBodyDetection_SimpleSignature() {
        // GIVEN
        let mckSignature = Signature()
        mckSignature.content = Self.basicSignature
        mckSignature.position = .afterReplyMessage
        let draftManager = DraftManager()

        // WHEN
        let isBodyEmpty = draftManager.isDraftBodyEmpty(Self.domBodyWithbasicSignature, for: mckSignature)

        XCTAssertTrue(isBodyEmpty, "we should detect and empty body")
    }

    // This pass, it is fine
    func testEmptyBodyDetection_ComplexSignature() {
        // GIVEN
        let mckSignature = Signature()
        mckSignature.content = Self.htmlSignature
        mckSignature.position = .beforeReplyMessage
        let draftManager = DraftManager()

        // WHEN
        let isBodyEmpty = draftManager.isDraftBodyEmpty(Self.htmlSignature, for: mckSignature)

        XCTAssertTrue(isBodyEmpty, "we should detect and empty body")
    }
}
