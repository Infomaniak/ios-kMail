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
import SwiftSoup
import XCTest

final class SignatureTests: XCTestCase {
    /// Some randon HTML content
    static let someMailContent = "<br><br><h1>Hello<h1></br></br>"

    /// A basic signature wrapped in the "editorUserSignature" class
    static let basicSignature =
        "<br><br><div class=\"editorUserSignature\"><p>test signature absolute bottom<br></p></div>"

    /// A JS script modify the body of the mail. This is the content of the webview after our scripts ran. Simple signature
    static let domBodyWithbasicSignature =
        "<div><br></div><div><br></div><div class=\"editorUserSignature\"><p>test signature absolute bottom<br></p></div><div><br></div>"

    /// A complex HTML signature wrapped in the "editorUserSignature" class
    static let htmlSignature =
        "<div style=\"width: 100%;\"><div style=\"float: left; margin-right: 20px;\"><div style=\"background-color: #0098ff; width: 45px; height: 45px; text-align: center; line-height: 45px; font-family: Arial; color: #ffffff; border-radius: 4px; font-size: 26px;\"><b>k</b><br></div></div><div style=\"margin-left: 65px;\"><h1 style=\"font-family: Arial; font-size: 22px; color: #0098ff; line-height: 22px; margin-bottom: 7px;\"><b>infomaniak</b><br></h1><p style=\"font-family: Arial; font-size: 15px; color: #666666; margin: 0;\">  Developer<br></p><div style=\"margin: 15px 0px 15px 0px; height: 1px; color: #ebebeb; background-color: #e0e0e0; border: none;\" width=\"400px\"><br></div><div style=\"font-family: Arial; font-size: 12px; color: #666666; margin-bottom: 7px;\">Rue Eugène-Marziano 25, 1227 Genève<br></div><div><span style=\"color: rgb(212, 68, 68);\"><b><span class=\"font\" style=\"font-family:Arial\"><span class=\"size\" style=\"font-size:12px\">Swiss Made</span></span></b></span><span style=\"color: #e0e0e0;\">&nbsp;|&nbsp;</span><span style=\"color: rgb(102, 102, 102);\"><span class=\"font\" style=\"font-family:Arial\"><span class=\"size\" style=\"font-size:12px\">ISO 27001 14001 50001 9001</span></span></span><br></div></div></div><p><br></p>"

    /// A JS script modify the body of the mail. This is the content of the webview after our scripts ran. Complex signature
    static let domBodyWithHtmlSignature =
        "<br><br><div class=\"editorUserSignature\"><div style=\"width: 100%;\"><div style=\"float: left; margin-right: 20px;\"><div style=\"background-color: #0098ff; width: 45px; height: 45px; text-align: center; line-height: 45px; font-family: Arial; color: #ffffff; border-radius: 4px; font-size: 26px;\"><b>k</b><br></div></div><div style=\"margin-left: 65px;\"><h1 style=\"font-family: Arial; font-size: 22px; color: #0098ff; line-height: 22px; margin-bottom: 7px;\"><b>infomaniak</b><br></h1><p style=\"font-family: Arial; font-size: 15px; color: #666666; margin: 0;\">  Developer<br></p><div style=\"margin: 15px 0px 15px 0px; height: 1px; color: #ebebeb; background-color: #e0e0e0; border: none;\" width=\"400px\"><br></div><div style=\"font-family: Arial; font-size: 12px; color: #666666; margin-bottom: 7px;\">Rue Eugène-Marziano 25, 1227 Genève<br></div><div><span style=\"color: rgb(212, 68, 68);\"><b><span class=\"font\" style=\"font-family:Arial\"><span class=\"size\" style=\"font-size:12px\">Swiss Made</span></span></b></span><span style=\"color: #e0e0e0;\">&nbsp;|&nbsp;</span><span style=\"color: rgb(102, 102, 102);\"><span class=\"font\" style=\"font-family:Arial\"><span class=\"size\" style=\"font-size:12px\">ISO 27001 14001 50001 9001</span></span></span><br></div></div></div><p><br></p></div>"

    static let domBodyWithContentAndSimpleSignature = """
    <div>Test<br></div><div><br></div><div>Some other content<br></div><div><br></div><p style="margin: 0.0px 0.0px 0.0px 0.0px; font: 23.4px Menlo; color: #4eb0cc; background-color: #292a30"><span style="font-weight: normal; font-style: normal; color: rgb(255, 122, 178);"><span class="font" style="font-family:Menlo-Regular"><span class="size" style="font-size:23.38px">private</span></span></span><span style="font-weight: normal; font-style: normal; color: rgba(255, 255, 255, 0.85);"><span class="font" style="font-family:Menlo-Regular"><span class="size" style="font-size:23.38px"> </span></span></span><span style="font-weight: normal; font-style: normal; color: rgb(255, 122, 178);"><span class="font" style="font-family:Menlo-Regular"><span class="size" style="font-size:23.38px">var</span></span></span><span style="font-weight: normal; font-style: normal; color: rgba(255, 255, 255, 0.85);"><span class="font" style="font-family:Menlo-Regular"><span class="size" style="font-size:23.38px"> </span></span></span><span style="font-weight: normal; font-style: normal;"><span class="font" style="font-family:Menlo-Regular"><span class="size" style="font-size:23.38px">accountManager</span></span></span><span style="font-weight: normal; font-style: normal; color: rgba(255, 255, 255, 0.85);"><span class="font" style="font-family:Menlo-Regular"><span class="size" style="font-size:23.38px">: </span></span></span><span style="font-weight: normal; font-style: normal; color: rgb(172, 242, 228);"><span class="font" style="font-family:Menlo-Regular"><span class="size" style="font-size:23.38px">AccountManager</span></span></span><span style="font-weight: normal; font-style: normal; color: rgba(255, 255, 255, 0.85);"><span class="font" style="font-family:Menlo-Regular"><span class="size" style="font-size:23.38px">!</span></span></span><br></p><div><br></div><div><input id="squire-selection-start" type="hidden"><input id="squire-selection-end" type="hidden"><br></div><div><br></div><div class="editorUserSignature"><p>test signature absolute bottom<br></p></div><div><br></div>
    """

    static let domBodyWithContentAndComplexSignature = """
    <div>Test&nbsp;<br></div><div><br></div><p style="margin: 0.0px 0.0px 0.0px 0.0px; font: 23.4px Menlo; color: #4eb0cc; background-color: #292a30"><span style="font-weight: normal; font-style: normal; color: rgba(255, 255, 255, 0.85);"><span class="font" style="font-family:Menlo-Regular"><span class="size" style="font-size:23.38px"><span class="Apple-converted-space">&nbsp; &nbsp; </span></span></span></span><span style="font-weight: normal; font-style: normal; color: rgb(255, 122, 178);"><span class="font" style="font-family:Menlo-Regular"><span class="size" style="font-size:23.38px">private</span></span></span><span style="font-weight: normal; font-style: normal; color: rgba(255, 255, 255, 0.85);"><span class="font" style="font-family:Menlo-Regular"><span class="size" style="font-size:23.38px"> </span></span></span><span style="font-weight: normal; font-style: normal; color: rgb(255, 122, 178);"><span class="font" style="font-family:Menlo-Regular"><span class="size" style="font-size:23.38px">var</span></span></span><span style="font-weight: normal; font-style: normal; color: rgba(255, 255, 255, 0.85);"><span class="font" style="font-family:Menlo-Regular"><span class="size" style="font-size:23.38px"> </span></span></span><span style="font-weight: normal; font-style: normal;"><span class="font" style="font-family:Menlo-Regular"><span class="size" style="font-size:23.38px">accountManager</span></span></span><span style="font-weight: normal; font-style: normal; color: rgba(255, 255, 255, 0.85);"><span class="font" style="font-family:Menlo-Regular"><span class="size" style="font-size:23.38px">: </span></span></span><span style="font-weight: normal; font-style: normal; color: rgb(172, 242, 228);"><span class="font" style="font-family:Menlo-Regular"><span class="size" style="font-size:23.38px">AccountManager</span></span></span><span style="font-weight: normal; font-style: normal; color: rgba(255, 255, 255, 0.85);"><span class="font" style="font-family:Menlo-Regular"><span class="size" style="font-size:23.38px">!</span></span></span><br></p><div><br></div><div class="editorUserSignature"><div style="width: 100%;"><div style="float: left; margin-right: 20px;"><div style="background-color: #0098ff; width: 45px; height: 45px; text-align: center; line-height: 45px; font-family: Arial; color: #ffffff; border-radius: 4px; font-size: 26px;"><b>k</b><br></div></div><div style="margin-left: 65px;"><h1 style="font-family: Arial; font-size: 22px; color: #0098ff; line-height: 22px; margin-bottom: 7px;"><b>infomaniak</b><br></h1><p style="font-family: Arial; font-size: 15px; color: #666666; margin: 0;">Coye de Brunélis Adrien -  Developer<br></p><div style="margin: 15px 0px 15px 0px; height: 1px; color: #ebebeb; background-color: #e0e0e0; border: none;" width="400px"><br></div><div style="font-family: Arial; font-size: 12px; color: #666666; margin-bottom: 7px;">Rue Eugène-Marziano 25, 1227 Genève<br></div><div><span style="color: rgb(212, 68, 68);"><b><span class="font" style="font-family:Arial"><span class="size" style="font-size:12px">Swiss Made</span></span></b></span><span style="color: #e0e0e0;">&nbsp;|&nbsp;</span><span style="color: rgb(102, 102, 102);"><span class="font" style="font-family:Arial"><span class="size" style="font-size:12px">ISO 27001 14001 50001 9001</span></span></span><br></div></div></div><p><br></p></div><div><br></div>
    """

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
            guard let signatureNode = try document.getElementsByClass(Constants.signatureWrapperIdentifier).first() else {
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
            guard let signatureNode = try document.getElementsByClass(Constants.signatureWrapperIdentifier).first() else {
                XCTFail("Unexpected signature not found")
                return
            }
            XCTAssertTrue(try (signatureNode.text().count) > 0, "We expect a non empty signature content")
        } catch {
            XCTFail("Unexpected :\(error)")
        }
    }

    // MARK: - Empty body detection

    /// Testing detection of empty body; abstracted of the signature used
    func testEmptyBodyDetection() {
        // GIVEN
        let draftManager = DraftManager()

        // WHEN
        do {
            let isBodyEmpty = try draftManager.isDraftBodyEmptyOfChanges(Self.domBodyWithbasicSignature)

            XCTAssertTrue(isBodyEmpty, "we should detect and empty body")
        } catch {
            XCTFail("Unexpected :\(error)")
        }
    }

    // MARK: - Not Empty body detection

    /// Testing detection of non empty body; abstracted of the signature used
    func testNonEmptyBodyDetection() {
        // GIVEN
        let draftManager = DraftManager()

        // WHEN
        do {
            let isBodyEmpty = try draftManager.isDraftBodyEmptyOfChanges(
                Self.domBodyWithContentAndSimpleSignature
            )

            XCTAssertFalse(isBodyEmpty, "we should detect a non empty body")
        } catch {
            XCTFail("Unexpected :\(error)")
        }
    }
}
