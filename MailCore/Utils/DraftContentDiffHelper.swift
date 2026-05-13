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
        return userBodyContainsUserEdition() || signatureHasChanged() || replyQuoteHasChanged()
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

        return savedSignatureText.normalizedReturns.trimmed != draftSignatureText.normalizedReturns.trimmed
    }

    private func replyQuoteHasChanged() -> Bool {
        guard let inReplyToUid = draft.inReplyToUid else {
            return false
        }

        return embeddedMessageHasChanged(
            messagePrimaryKey: inReplyToUid,
            cssSelector: ".\(Constants.replyQuoteHTMLClass) > blockquote"
        )
    }

    private func embeddedMessageHasChanged(messagePrimaryKey: String, cssSelector: String) -> Bool {
        guard let fetchedMessage = transactionable.fetchObject(ofType: Message.self, forPrimaryKey: messagePrimaryKey) else {
            return false
        }

        guard let parsedDraft = try? SwiftSoup.parse(draft.body),
              let parsedEmbeddedMessage = try? parsedDraft.select(cssSelector).first(),
              let parsedEmbeddedMessageText = try? parsedEmbeddedMessage.text()
        else { return false }

        guard let fetchedMessageBody = fetchedMessage.body?.value else {
            return false
        }

        var parsedFetchedMessageText: String? = fetchedMessageBody
        if fetchedMessage.body?.type == .textHtml {
            let parsedFetchedMessage = try? SwiftSoup.parse(fetchedMessageBody)
            parsedFetchedMessageText = try? parsedFetchedMessage?.text()
        }

        guard let parsedFetchedMessageText else {
            return false
        }

        return parsedFetchedMessageText.normalizedReturns.trimmed != parsedEmbeddedMessageText.normalizedReturns.trimmed
    }
}
