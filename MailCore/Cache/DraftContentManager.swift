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
import MailResources
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

    private let messageReply: MessageReply?
    private let mailboxManager: MailboxManager
    private let incompleteDraft: Draft

    public init(incompleteDraft: Draft, messageReply: MessageReply?, mailboxManager: MailboxManager) {
        self.incompleteDraft = incompleteDraft.freezeIfNeeded()
        self.messageReply = messageReply
        self.mailboxManager = mailboxManager
    }
}

// MARK: - Load data

extension DraftContentManager {
    private func loadCompleteDraftBody() async throws -> CompleteDraftResult {
        var completeDraftBody: String
        var attachments = [Attachment]()
        let shouldAddSignatureText: Bool

        if let messageReply {
            // New draft created either with reply or forward
            async let completeDraftReplyingBody = try await loadReplyingMessageAndFormat(
                messageReply.frozenMessage,
                replyMode: messageReply.replyMode
            )
            async let replyingAttachments = try await loadReplyingAttachments(
                message: messageReply.frozenMessage,
                replyMode: messageReply.replyMode
            )

            completeDraftBody = try await completeDraftReplyingBody
            attachments = try await replyingAttachments
            shouldAddSignatureText = true
        } else if incompleteDraft.isLoadedRemotely {
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

    private func loadReplyingMessage(_ message: Message, replyMode: ReplyMode) async throws -> Message {
        if !message.fullyDownloaded {
            try await mailboxManager.message(message: message)
        }

        guard let freshMessage = message.thaw() else { throw MailError.unknownError }
        freshMessage.realm?.refresh()
        return freshMessage
    }

    private func loadReplyingMessageAndFormat(_ message: Message, replyMode: ReplyMode) async throws -> String {
        let replyingMessage = try await loadReplyingMessage(message, replyMode: replyMode)
        return try await formatReplyingBody(of: replyingMessage, replyingMode: replyMode)
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

// MARK: - Write draft

public extension DraftContentManager {
    func prepareCompleteDraft() async throws -> Signature {
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

    func replaceContent(subject: String? = nil, body: String) async {
        guard let draft = try? getFrozenDraft() else { return }
        guard let parsedMessage = try? await SwiftSoup.parse(draft.body) else { return }

        var extractedElements = ""
        for itemToExtract in Draft.appendedHTMLElements {
            if let element = try? await SwiftSoupUtils(document: parsedMessage).extractHTML(".\(itemToExtract)") {
                extractedElements.append(element)
            }
        }

        let realm = mailboxManager.getRealm()
        guard let liveDraft = draft.thaw() else { return }
        try? realm.write {
            if let subject {
                liveDraft.subject = subject
            }
            liveDraft.body = "<p>\(body.withNewLineIntoHTML)</p>\(extractedElements)"
        }
        NotificationCenter.default.post(name: .updateComposeMessageBody, object: nil)
    }

    private func writeCompleteDraft(
        completeBody: String,
        signature: Signature,
        shouldAddSignatureText: Bool,
        attachments: [Attachment]
    ) throws {
        let realm = mailboxManager.getRealm()
        let liveIncompleteDraft = try getLiveDraft()

        try? realm.write {
            if liveIncompleteDraft.identityId == nil || liveIncompleteDraft.identityId?.isEmpty == true {
                liveIncompleteDraft.identityId = "\(signature.id)"
                if shouldAddSignatureText {
                    liveIncompleteDraft.rawSignature = signature.content
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
}

// MARK: - Reply and Forward quotes

extension DraftContentManager {
    private func formatReplyingBody(of message: Message, replyingMode: ReplyMode) async throws -> String {
        let content: String
        switch replyingMode {
        case .reply, .replyAll:
            content = try await formatReply(message: message)
        case .forward:
            content = try await formatForward(message: message)
        }

        return "<br><br>\(content)"
    }

    private func formatReply(message: Message) async throws -> String {
        guard let root = try await SwiftSoupUtils(fromHTMLFragment: Constants.replyRoot).extractParentElement() else { return "" }

        try appendTextLine(
            to: root,
            text: MailResourcesStrings.Localizable.messageReplyHeader(
                Constants.localizedDate(message.date),
                message.formattedFrom
            ),
            withBR: false
        )
        try await appendBlockquote(to: root) { blockquote in
            try await appendReplyingBody(to: blockquote, message: message)
        }

        return try root.outerHtml()
    }

    private func formatForward(message: Message) async throws -> String {
        guard let root = try await SwiftSoupUtils(fromHTMLFragment: Constants.forwardRoot).extractParentElement()
        else { return "" }

        try appendTextLine(to: root, text: "---------- \(MailResourcesStrings.Localizable.messageForwardHeader) ----------")
        try appendTextLine(to: root, text: "\(MailResourcesStrings.Localizable.fromTitle) \(message.formattedFrom)")
        try appendTextLine(
            to: root,
            text: "\(MailResourcesStrings.Localizable.dateTitle) \(Constants.localizedDate(message.date))"
        )
        try appendTextLine(to: root, text: "\(MailResourcesStrings.Localizable.subjectTitle) \(message.formattedSubject)")
        try appendRecipientLine(to: root, title: MailResourcesStrings.Localizable.toTitle, recipients: message.to)
        try appendRecipientLine(to: root, title: MailResourcesStrings.Localizable.ccTitle, recipients: message.cc)
        try appendTextLine(to: root, text: "")
        try appendTextLine(to: root, text: "")
        try await appendReplyingBody(to: root, message: message)

        return try root.outerHtml()
    }

    private func appendTextLine(to element: Element, text: String, withBR: Bool = true) throws {
        let div = try element.appendElement("div")
        try div.text(text)
        try div.appendElement("br")
    }

    private func appendRecipientLine(to element: Element, title: String, recipients: List<Recipient>) throws {
        guard !recipients.isEmpty else { return }
        let formattedList = ListFormatter.localizedString(byJoining: recipients.map(\.htmlDescription))
        try appendTextLine(to: element, text: "\(title) \(formattedList)")
    }

    private func appendBlockquote(to element: Element, completion: (Element) async throws -> Void) async throws {
        let blockquote = try element.appendElement("blockquote")
        try await completion(blockquote)
    }

    private func appendReplyingBody(to element: Element, message: Message) async throws {
        guard let replyingBody = try await extractHTMLFromReplyingBody(of: message) else { return }
        try element.append(replyingBody)
    }

    private func extractHTMLFromReplyingBody(of message: Message) async throws -> String? {
        guard let value = message.body?.value else { return nil }

        guard message.body?.type != .textPlain else {
            return try await MessageWebViewUtils.createHTMLForPlainText(text: value)
        }

        let document = try await SwiftSoup.parse(value)
        guard let head = document.head(), let body = document.body() else { return nil }

        let styleElementsFromHead = try head.getElementsByTag("style").array()
        try body.insertChildren(0, styleElementsFromHead)

        let bodyHTML = try body.html()
        return bodyHTML
    }
}

// MARK: - Signatures

extension DraftContentManager {
    public func updateSignature(with newSignature: Signature) {
        do {
            let liveIncompleteDraft = try getLiveDraft()

            let parsedMessage = try SwiftSoup.parse(liveIncompleteDraft.body)
            // If we find the previous signature, we replace it with the new one
            // otherwise we append the signature at the end of the document
            if let foundSignatureDiv = try parsedMessage.select(".\(Constants.signatureHTMLClass)").first {
                try foundSignatureDiv.html(newSignature.content)
            } else if let body = parsedMessage.body() {
                let signatureDiv = try body.appendElement("div")
                try signatureDiv.addClass(Constants.signatureHTMLClass)
                try signatureDiv.html(newSignature.content)
            }

            let realm = mailboxManager.getRealm()
            try? realm.write {
                // Keep up to date the rawSignature
                liveIncompleteDraft.rawSignature = newSignature.content
                liveIncompleteDraft.identityId = "\(newSignature.id)"
                liveIncompleteDraft.body = try parsedMessage.outerHtml()
            }
            NotificationCenter.default.post(name: .updateComposeMessageBody, object: nil)
        } catch {
            DDLogError("An error occurred while transforming the DOM of the draft: \(error)")
        }
    }

    /// Load best signature from local DB
    private func loadMostFittingSignature() async throws -> Signature {
        do {
            let storedSignatures = mailboxManager.getStoredSignatures()
            let defaultSignature = try getDefaultSignature(userSignatures: storedSignatures)

            // If draft already has an identity, return corresponding signature
            if let storedDraft = mailboxManager.getRealm().object(ofType: Draft.self, forPrimaryKey: incompleteDraft.localUUID),
               let identityId = storedDraft.identityId {
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
        guard let previousMessage = messageReply?.frozenMessage else { return defaultSignature }

        let signaturesGroupedByEmail = Dictionary(grouping: userSignatures, by: \.senderEmail)
        let recipientsFieldsToCheck = [\Message.to, \Message.from, \Message.cc]
        for field in recipientsFieldsToCheck {
            if let signature = findSignatureInRecipients(
                recipients: previousMessage[keyPath: field],
                signaturesGroupedByEmail: signaturesGroupedByEmail
            ) {
                return signature.freezeIfNeeded()
            }
        }

        return defaultSignature
    }

    private func findSignatureInRecipients(recipients: List<Recipient>,
                                           signaturesGroupedByEmail: [String: [Signature]]) -> Signature? {
        let matchingEmailRecipients = recipients.filter { signaturesGroupedByEmail[$0.email] != nil }.toArray()
        guard !matchingEmailRecipients.isEmpty else { return nil }

        var bestSignature: Signature?
        var bestMatchingScore: SignatureMatch?

        for recipient in matchingEmailRecipients {
            guard let signatures = signaturesGroupedByEmail[recipient.email],
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
}

// MARK: - Helpers

extension DraftContentManager {
    public func getReplyingBody() async throws -> Body? {
        guard let messageReply else { return nil }
        return try await loadReplyingMessage(messageReply.frozenMessage, replyMode: messageReply.replyMode).body?.freezeIfNeeded()
    }

    private func getLiveDraft() throws -> Draft {
        let realm = mailboxManager.getRealm()
        guard let liveDraft = realm.object(ofType: Draft.self, forPrimaryKey: incompleteDraft.localUUID) else {
            throw MailError.unknownError
        }
        return liveDraft
    }

    private func getFrozenDraft() throws -> Draft {
        return try getLiveDraft().freezeIfNeeded()
    }
}
