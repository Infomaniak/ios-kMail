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

import Foundation
import InfomaniakCoreDB
@testable import MailCore
import MailCoreUI
import RealmSwift
import Testing

@Suite
struct UIAttachmentTests {
    @Test("Snapshots survive Realm deletion and preserve parent paths and frozen identity")
    func managedSnapshot() throws {
        let accessor = MailCoreRealmAccessor(realmConfiguration: Realm.Configuration(inMemoryIdentifier: UUID().uuidString))
        let executor = TransactionExecutor(realmAccessible: accessor)
        defer { try? executor.writeTransaction { $0.deleteAll() } }
        let message = Message()
        message.uid = "123@folder"
        message.folderId = "folder"
        message.attachments.append(makeAttachment())
        try executor.writeTransaction { $0.add(message) }

        let attachment = try #require(executor.fetchObject(ofType: Message.self, forPrimaryKey: message.uid)?.attachments.first)
        let localURL = attachment.getLocalURL(userId: 1, mailboxId: 2)
        let snapshot = UIAttachment(attachment: attachment, messageUid: message.uid, localURL: localURL)
        #expect(localURL.pathComponents.suffix(6) == ["1", "2", "folder", "123", "1", "document.pdf"])
        #expect(UIAttachment.id(for: attachment.freeze(), messageUid: message.uid) == snapshot.id)

        try executor.writeTransaction { realm in
            realm.delete(realm.objects(Message.self))
        }
        #expect(attachment.isInvalidated)
        #expect(snapshot.name == "document.pdf")
        #expect(snapshot.size == 42)
        #expect(snapshot.localURL == localURL)
        #expect(snapshot.icon.name == AttachmentHelper(type: "application/pdf").icon.name)
    }

    @Test("Wallet classification is preserved in UI snapshots")
    func walletClassification() {
        let cases = [
            ("Application/Vnd.Apple.Pkpass; charset=binary", "ticket.bin", true),
            ("application/octet-stream", "ticket.PKPASS", true),
            ("application/pdf", "ticket.pkpass.pdf", false)
        ]
        for (mimeType, name, expected) in cases {
            let attachment = makeAttachment(mimeType: mimeType, name: name)
            let snapshot = UIAttachment(
                attachment: attachment,
                messageUid: "message",
                localURL: attachment.getLocalURL(userId: 1, mailboxId: 2)
            )
            #expect(snapshot.isWalletPass == expected)
        }
    }

    @Test("SwissTransfer files use the same independent display model")
    func swissTransferSnapshot() {
        let file = MailCore.File()
        file.uuid = "file"
        file.name = "document.pdf"
        file.size = 42
        file.type = "application/pdf"
        let snapshot = UIAttachment(swissTransferFile: file, transferId: "transfer")
        let otherTransfer = UIAttachment(swissTransferFile: file, transferId: "other-transfer")
        file.name = "changed.txt"

        #expect(snapshot.id == .swissTransfer(transferId: "transfer", fileId: "file"))
        #expect(snapshot.id != otherTransfer.id)
        #expect(snapshot.name == "document.pdf")
        #expect(snapshot.size == 42)
        #expect(snapshot.mimeType == "application/pdf")
        #expect(snapshot.icon.name == AttachmentHelper(type: "application/pdf").icon.name)
        #expect(!snapshot.isInline)
        #expect(!snapshot.isWalletPass)
        #expect(snapshot.localURL == nil)
        #expect(snapshot.temporaryLocalURL == nil)
        #expect(snapshot.availableLocalURL == nil)
    }

    @Test("File readiness updates without mutating the UI snapshot")
    func localFileReadiness() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let canonicalURL = directory.appendingPathComponent("download.pdf")
        let temporaryURL = directory.appendingPathComponent("upload.pdf")
        let attachment = makeAttachment()
        attachment.temporaryLocalUrl = temporaryURL.path
        let snapshot = UIAttachment(attachment: attachment, draftLocalUUID: "draft", localURL: canonicalURL)

        #expect(snapshot.availableLocalURL == nil)
        try Data("upload".utf8).write(to: temporaryURL)
        #expect(snapshot.availableLocalURL == temporaryURL)
        try Data("download".utf8).write(to: canonicalURL)
        #expect(snapshot.availableLocalURL == canonicalURL)
        try FileManager.default.removeItem(at: canonicalURL)
        #expect(snapshot.availableLocalURL == temporaryURL)
    }

    @Test("Upload completion keeps the resolved download URL when opening a stale snapshot")
    func staleSnapshotUsesResolvedDownloadURL() throws {
        let accessor = MailCoreRealmAccessor(realmConfiguration: Realm.Configuration(inMemoryIdentifier: UUID().uuidString))
        let executor = TransactionExecutor(realmAccessible: accessor)
        defer { try? executor.writeTransaction { $0.deleteAll() } }
        let message = Message()
        message.uid = "123@folder"
        message.folderId = UUID().uuidString
        message.attachments.append(makeAttachment())
        try executor.writeTransaction { $0.add(message) }

        let attachment = try #require(executor.fetchObject(ofType: Message.self, forPrimaryKey: message.uid)?.attachments.first)
        let staleSnapshot = UIAttachment(
            attachment: attachment,
            draftLocalUUID: "draft",
            localURL: attachment.getLocalURL(userId: 1, mailboxId: 2)
        )

        let uploadedAttachment = makeAttachment()
        uploadedAttachment.uuid = attachment.uuid
        uploadedAttachment.partId = "uploaded-part"
        uploadedAttachment.temporaryLocalUrl = "/uploaded/temporary/document.pdf"
        try executor.writeTransaction { _ in
            attachment.update(with: uploadedAttachment)
        }
        let frozenAttachment = attachment.freezeIfNeeded()
        let resolvedURL = frozenAttachment.getLocalURL(userId: 1, mailboxId: 2)

        #expect(staleSnapshot.temporaryLocalURL == nil)
        #expect(frozenAttachment.temporaryLocalUrl == "/uploaded/temporary/document.pdf")
        #expect(resolvedURL != staleSnapshot.localURL)
    }

    private func makeAttachment(mimeType: String = "application/pdf", name: String = "document.pdf") -> MailCore.Attachment {
        MailCore.Attachment(partId: "1", mimeType: mimeType, size: 42, name: name, disposition: .attachment)
    }
}
