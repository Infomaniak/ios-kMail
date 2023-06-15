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

@testable import Mail
import MailResources
@testable import SwiftSoup
import XCTest

final class MailBase64Encoder: XCTestCase {
    // MARK: - Test simple image

    func testEncodeSomeImage() {
        // GIVEN
        let contentId = "1337"
        let mimeType = "image/png"
        let htmlBody = """
        <html>
        <head>
        </head>
        <body>
            <h1> this is a test </h1>
            <img src="cid:\(contentId)"/>
        </body>
        </html>
        """
        var processedBody: String? = htmlBody
        let base64Encoder = Base64Encoder()
        guard let imageData = MailResourcesAsset.allFolders.image.pngData() else {
            XCTFail("Unexpected")
            return
        }
        let imageBase64 = imageData.base64EncodedString()

        // WHEN
        base64Encoder.replaceContentIdForBase64Image(
            in: &processedBody,
            contentId: contentId,
            mimeType: mimeType,
            contentData: imageData
        )

        // THEN
        guard let processedBody = processedBody else {
            XCTFail("Unexpected")
            return
        }

        XCTAssertNotEqual(htmlBody, processedBody)
        XCTAssertGreaterThan(processedBody.count, htmlBody.count, "processed body should be longer with the image")

        // Can I still access the IMG node
        do {
            let document = try SwiftSoup.parse(processedBody)
            guard let imageNode = try document.getElementsByTag("img").first() else {
                XCTFail("we should be able to load the image node")
                return
            }

            guard let imageSrc = imageNode.attributes?.get(key: "src") else {
                XCTFail("the img node should exist")
                return
            }
            XCTAssertTrue(imageSrc.contains(imageBase64), "the image node should contain the base 64 encoded image")

        } catch Exception.Error(let type, let message) {
            XCTFail("Unexpected Exception :\(message) :\(type)")
        } catch {
            XCTFail("Unexpected error :\(error)")
        }
    }

    // MARK: - Test zero size image

    func testEncodeEmptyImage() {
        // GIVEN
        let contentId = "1337"
        let mimeType = "image/png"
        let htmlBody = """
        <html>
        <head>
        </head>
        <body>
            <h1> this is a test </h1>
            <img src="cid:\(contentId)"/>
        </body>
        </html>
        """
        var processedBody: String? = htmlBody
        let base64Encoder = Base64Encoder()
        let imageData = Data()
        let expectedResult = "data:image/png;base64,"

        // WHEN
        base64Encoder.replaceContentIdForBase64Image(
            in: &processedBody,
            contentId: contentId,
            mimeType: mimeType,
            contentData: imageData
        )

        // THEN
        guard let processedBody = processedBody else {
            XCTFail("Unexpected")
            return
        }

        XCTAssertNotEqual(htmlBody, processedBody)
        XCTAssertGreaterThan(processedBody.count, htmlBody.count, "processed body should be longer with the image")

        // Can I still access the IMG node
        do {
            let document = try SwiftSoup.parse(processedBody)
            guard let imageNode = try document.getElementsByTag("img").first() else {
                XCTFail("we should be able to load the image node")
                return
            }

            guard let imageSrc = imageNode.attributes?.get(key: "src") else {
                XCTFail("the img node should exist")
                return
            }
            XCTAssertEqual(imageSrc, expectedResult)

        } catch Exception.Error(let type, let message) {
            XCTFail("Unexpected Exception :\(message) :\(type)")
        } catch {
            XCTFail("Unexpected error :\(error)")
        }
    }
}
