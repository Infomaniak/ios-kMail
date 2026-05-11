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

import InfomaniakCoreDB
import SwiftSoup

public struct DraftContentDiffHelper {
    private let draft: Draft
    private let transactionable: Transactionable

    public init(draft: Draft, transactionable: Transactionable) {
        self.draft = draft
        self.transactionable = transactionable
    }

    public func containsUserEdition() -> Bool {
        return userBodyContainsUserEdition() || signatureHasChanged() || replyOrForwardQuoteHasChanged()
    }

    public func userBodyContainsUserEdition() -> Bool {
        guard !draft.body.isEmpty, let document = try? SwiftSoup.parse(draft.body) else {
            return false
        }

        for itemToExtract in Draft.appendedHTMLElements {
            _ = try? document.getElementsByClass(itemToExtract).remove()
        }

        return document.hasText()
    }

    private func signatureHasChanged() -> Bool {
        guard let savedSignature = draft.rawSignature else {
            return false
        }

        guard !draft.body.isEmpty, let parsedDraftBody = try? SwiftSoup.parse(draft.body) else {
            return false
        }

        guard let signatureNode = try? parsedDraftBody.getElementsByClass(Constants.signatureHTMLClass).first() else {
            return true
        }

        let draftSignatureText = (try? signatureNode.text()) ?? ""
        guard let parsedSavedSignature = try? SwiftSoup.parse(savedSignature),
              let savedSignatureText = try? parsedSavedSignature.text()
        else { return true }

        return savedSignatureText.trimmed != draftSignatureText.trimmed
    }

    private func replyOrForwardQuoteHasChanged() -> Bool {
        if let inReplyToUid = draft.inReplyToUid {
            if embeddedMessageHasChanged(
                messagePrimaryKey: inReplyToUid,
                cssSelector: quoteSelector(forCSSClass: Constants.replyQuoteHTMLClass)
            ) {
                return true
            }
        }

        if let forwardedUid = draft.forwardedUid {
            if embeddedMessageHasChanged(
                messagePrimaryKey: forwardedUid,
                cssSelector: quoteSelector(forCSSClass: Constants.forwardQuoteHTMLClass)
            ) {
                return true
            }
        }

        return false
    }

    private func embeddedMessageHasChanged(messagePrimaryKey: String, cssSelector: String) -> Bool {
        guard let fetchedMessage = transactionable.fetchObject(ofType: Message.self, forPrimaryKey: messagePrimaryKey) else {
            return false
        }

        guard let parsedDraft = try? SwiftSoup.parse(draft.body),
              let parsedEmbeddedMessage = try? parsedDraft.select(cssSelector).first(),
              let parsedEmbeddedMessageText = try? parsedEmbeddedMessage.text()
        else { return false }

        guard let fetchedMessageBody = fetchedMessage.body?.value,
              let parsedFetchedMessage = try? SwiftSoup.parse(fetchedMessageBody),
              let parsedFetchedMessageText = try? parsedFetchedMessage.text()
        else { return false }

        return parsedFetchedMessageText.trimmed != parsedEmbeddedMessageText.trimmed
    }

    private func quoteSelector(forCSSClass cssClass: String) -> String {
        return ".\(cssClass) > blockquote"
    }
}
