/*
 Infomaniak Mail - iOS App
 Copyright (C) 2026 Infomaniak Network SA

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
import Testing

@Suite
struct AttachmentWalletPassTests {
    @Test("Recognizes Wallet passes by MIME type or filename")
    func recognizesWalletPass() {
        let byType = Attachment(partId: "1", mimeType: "Application/Vnd.Apple.Pkpass; charset=binary",
                                size: 1, name: "ticket.bin", disposition: .attachment)
        let byName = Attachment(partId: "2", mimeType: "application/octet-stream",
                                size: 1, name: "ticket.PKPASS", disposition: .attachment)

        #expect(byType.isWalletPass)
        #expect(byName.isWalletPass)
    }

    @Test("Other attachments are not treated as Wallet passes")
    func rejectsOtherAttachments() {
        let attachment = Attachment(partId: "1", mimeType: "application/pdf",
                                    size: 1, name: "ticket.pdf", disposition: .attachment)
        let misleadingName = Attachment(partId: "2", mimeType: "application/pdf",
                                        size: 1, name: "ticket.pkpass.pdf", disposition: .attachment)

        #expect(!attachment.isWalletPass)
        #expect(!misleadingName.isWalletPass)
    }
}
