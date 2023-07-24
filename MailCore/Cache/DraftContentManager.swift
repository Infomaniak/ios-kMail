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

import CocoaLumberjackSwift
import Foundation
import RealmSwift
import Sentry
import SwiftSoup

enum SignatureMatch: Int, Comparable {
    case exactMatchDefault = 3
    case exactMatch = 2
    case emailMatchDefault = 1
    case emailMatch = 0

    static func < (lhs: SignatureMatch, rhs: SignatureMatch) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

public class DraftContentManager: ObservableObject {
    struct CompleteDraftResult {
        let body: String
        let attachments: [Attachment]
        let shouldAddSignatureText: Bool
    }

    let messageReply: MessageReply?
    let mailboxManager: MailboxManager
    let incompleteDraft: Draft

    public init(incompleteDraft: Draft, messageReply: MessageReply?, mailboxManager: MailboxManager) {
        self.incompleteDraft = incompleteDraft.freezeIfNeeded()
        self.messageReply = messageReply
        self.mailboxManager = mailboxManager
    }

    public func prepareCompleteDraft() async throws -> Signature {
        async let draftBodyResult = try await loadCompleteDraftBody()
        async let signature = try await loadMostFittingSignature()

        try await writeCompleteDraft(
            completeBody: draftBodyResult.body,
            signature: signature,
            shouldAddSignatureText: draftBodyResult.shouldAddSignatureText,
            attachments: draftBodyResult.attachments
        )

        return try await signature
    }

    public func updateSignature(with newSignature: Signature) {
        let realm = mailboxManager.getRealm()
        guard let liveIncompleteDraft = realm.object(ofType: Draft.self, forPrimaryKey: incompleteDraft.localUUID) else {
            return
        }

        do {
            let parsedMessage = try SwiftSoup.parse(liveIncompleteDraft.body)
            // If we find the previous signature, we replace it with the new one
            // otherwise we append the signature at the end of the document
            if let foundSignatureDiv = try parsedMessage.select(".\(Constants.signatureWrapperIdentifier)").first {
                try foundSignatureDiv.html(newSignature.content)
            } else if let body = parsedMessage.body() {
                let signatureDiv = try body.appendElement("div")
                try signatureDiv.addClass(Constants.signatureWrapperIdentifier)
                try signatureDiv.html(newSignature.content)
            }

            try? realm.write {
                liveIncompleteDraft.identityId = "\(newSignature.id)"
                liveIncompleteDraft.body = try parsedMessage.outerHtml()
            }
        } catch {
            DDLogError("An error occurred while transforming the DOM of the draft: \(error)")
        }
    }

    private func loadCompleteDraftBody() async throws -> CompleteDraftResult {
        var completeDraftBody: String
        var attachments = [Attachment]()
        let shouldAddSignatureText: Bool

        if let messageReply {
            // New draft created either with reply or forward
            async let completeDraftReplyingBody = try await loadReplyingBody(
                message: messageReply.message,
                replyMode: messageReply.replyMode
            )
            async let replyingAttachments = try await loadReplyingAttachments(
                message: messageReply.message,
                replyMode: messageReply.replyMode
            )

            completeDraftBody = try await completeDraftReplyingBody
            attachments = try await replyingAttachments
            shouldAddSignatureText = true
        } else if incompleteDraft.messageUid != nil && incompleteDraft.remoteUUID.isEmpty {
            // Draft loaded remotely
            completeDraftBody = try await loadCompleteDraftIfNeeded()
            shouldAddSignatureText = false
        } else if !incompleteDraft.remoteUUID.isEmpty {
            // Draft loaded remotely but we have it locally
            completeDraftBody = incompleteDraft.body
            shouldAddSignatureText = false
        } else {
            // New draft
            completeDraftBody = ""
            shouldAddSignatureText = true
        }

        return CompleteDraftResult(
            body: completeDraftBody,
            attachments: attachments,
            shouldAddSignatureText: shouldAddSignatureText
        )
    }

    private func writeCompleteDraft(
        completeBody: String,
        signature: Signature,
        shouldAddSignatureText: Bool,
        attachments: [Attachment]
    ) throws {
        let realm = mailboxManager.getRealm()
        guard let liveIncompleteDraft = realm.object(ofType: Draft.self, forPrimaryKey: incompleteDraft.localUUID) else {
            throw MailError.unknownError
        }

        try? realm.write {
            if liveIncompleteDraft.identityId == nil || liveIncompleteDraft.identityId?.isEmpty == true {
                liveIncompleteDraft.identityId = "\(signature.id)"
                if shouldAddSignatureText {
                    liveIncompleteDraft.body = signature.appendSignature(to: completeBody)
                }
            } else {
                liveIncompleteDraft.body = completeBody
            }

            for attachment in attachments {
                liveIncompleteDraft.attachments.append(attachment)
            }
        }
    }

    private func loadMostFittingSignature() async throws -> Signature {
        do {
            try await mailboxManager.refreshAllSignatures()
            let storedSignatures = mailboxManager.getStoredSignatures()
            let defaultSignature = try getDefaultSignature(userSignatures: storedSignatures)

            // If draft has an identity, return corresponding signature
            if let identityId = incompleteDraft.identityId {
                return getSignature(for: identityId, userSignatures: storedSignatures) ?? defaultSignature
            }

            // If draft is a new message or a forward, use default signature
            guard let messageReply, messageReply.replyMode == .reply || messageReply.replyMode == .replyAll else {
                return defaultSignature
            }

            return guessMostFittingSignature(userSignatures: storedSignatures, defaultSignature: defaultSignature)
        } catch {
            SentrySDK.capture(message: "We failed to fetch Signatures. This will close the Editor.") { scope in
                scope.setExtras([
                    "errorMessage": error.localizedDescription,
                    "error": "\(error)"
                ])
            }
            throw error
        }
    }

    private func getSignature(for identity: String, userSignatures: [Signature]) -> Signature? {
        return userSignatures.first { identity == "\($0.id)" }?.freezeIfNeeded()
    }

    private func getDefaultSignature(userSignatures: [Signature]) throws -> Signature {
        guard let defaultSignature = userSignatures.defaultSignature else {
            throw MailError.defaultSignatureMissing
        }
        return defaultSignature.freezeIfNeeded()
    }

    private func guessMostFittingSignature(userSignatures: [Signature], defaultSignature: Signature) -> Signature {
        guard let previousMessage = messageReply?.message else { return defaultSignature }

        var signaturesForEmail = [String: [Signature]]()
        for signature in userSignatures {
            signaturesForEmail[signature.senderEmail, default: []].append(signature)
        }

        let recipientsFieldsToCheck = [\Message.to, \Message.from, \Message.cc]
        for field in recipientsFieldsToCheck {
            if let signature = findSignatureInRecipients(
                recipients: previousMessage[keyPath: field],
                signaturesForEmail: signaturesForEmail
            ) {
                return signature.freezeIfNeeded()
            }
        }

        return defaultSignature
    }

    private func findSignatureInRecipients(recipients: List<Recipient>, signaturesForEmail: [String: [Signature]]) -> Signature? {
        let matchingEmailRecipients = recipients.filter { signaturesForEmail[$0.email] != nil }.toArray()
        guard !matchingEmailRecipients.isEmpty else { return nil }

        var bestSignature: Signature?
        var bestMatchingScore: SignatureMatch?

        for recipient in matchingEmailRecipients {
            guard let signatures = signaturesForEmail[recipient.email],
                  let (signature, computedScore) = computeScore(for: signatures, recipient: recipient) else { continue }

            if computedScore == .exactMatchDefault {
                return signature
            }

            if bestMatchingScore == nil || computedScore > bestMatchingScore! {
                bestMatchingScore = computedScore
                bestSignature = signature
            }
        }

        return bestSignature
    }

    private func computeScore(for signatures: [Signature], recipient: Recipient) -> (Signature, SignatureMatch)? {
        var bestResult: (Signature, SignatureMatch)?

        for signature in signatures {
            let computedScore = computeScore(for: signature, recipient: recipient)
            if computedScore == .exactMatchDefault {
                return (signature, computedScore)
            }

            if bestResult == nil || computedScore > bestResult!.1 {
                bestResult = (signature, computedScore)
            }
        }

        return bestResult
    }

    private func computeScore(for signature: Signature, recipient: Recipient) -> SignatureMatch {
        let isExactMatch = signature.senderName == recipient.name
        let isDefault = signature.isDefault

        if isExactMatch {
            return isDefault ? .exactMatchDefault : .exactMatch
        }
        return isDefault ? .emailMatchDefault : .emailMatch
    }

    private func loadReplyingBody(message: Message, replyMode: ReplyMode) async throws -> String {
        if !message.fullyDownloaded {
            try await mailboxManager.message(message: message)
        }

        guard let freshMessage = message.thaw() else { throw MailError.unknownError }
        freshMessage.realm?.refresh()
        return Draft.replyingBody(message: freshMessage, replyMode: replyMode)
    }

    private func loadReplyingAttachments(message: Message, replyMode: ReplyMode) async throws -> [Attachment] {
        guard replyMode == .forward else { return [] }
        let attachments = try await mailboxManager.apiFetcher.attachmentsToForward(
            mailbox: mailboxManager.mailbox,
            message: message
        ).attachments

        return attachments
    }

    private func loadCompleteDraftIfNeeded() async throws -> String {
        guard let associatedMessage = mailboxManager.getRealm()
            .object(ofType: Message.self, forPrimaryKey: incompleteDraft.messageUid)?.freeze()
        else { throw MailError.localMessageNotFound }

        let remoteDraft = try await mailboxManager.apiFetcher.draft(from: associatedMessage)

        remoteDraft.localUUID = incompleteDraft.localUUID
        remoteDraft.action = .save
        remoteDraft.delay = incompleteDraft.delay

        let realm = mailboxManager.getRealm()
        try? realm.safeWrite {
            realm.add(remoteDraft.detached(), update: .modified)
        }

        return remoteDraft.body
    }
}
