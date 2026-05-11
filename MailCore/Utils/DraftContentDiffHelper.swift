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

import Foundation
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
        guard !draft.body.isEmpty, let document = try? SwiftSoup.parse(draft.body) else {
            return false
        }

        guard let signatureNode = try? document.getElementsByClass(Constants.signatureHTMLClass).first() else {
            return false
        }

        let signatureNodeText = (try? signatureNode.text()) ?? ""
        guard let rawSignature = draft.rawSignature,
              let rawSignatureDocument = try? SwiftSoup.parse(rawSignature),
              let rawSignatureText = try? rawSignatureDocument.text() else {
            return false
        }

        return rawSignatureText.trimmed == signatureNodeText.trimmed
    }

    private func replyOrForwardQuoteHasChanged() -> Bool {
        if let inReplyToUid = draft.inReplyToUid,
           let message = transactionable.fetchObject(ofType: Message.self, forPrimaryKey: draft.inReplyToUid),
           let replyBody = message.body?.value?.trimmed {
            let draftDocument = try? SwiftSoup.parse(draft.body)
            let replyQuote = try? draftDocument?.select(".\(Constants.replyQuoteHTMLClass) > blockquote").first()?.text().trimmed

            let replyDocument = try? SwiftSoup.parse(replyBody)
            let replyText = try? replyDocument?.text().trimmed

            if replyText != replyQuote {
                return false
            }
        }

        if let forwardedUid = draft.forwardedUid,
           let message = transactionable.fetchObject(ofType: Message.self, forPrimaryKey: forwardedUid),
           let forwardBody = message.body?.value?.trimmed {
            let draftDocument = try? SwiftSoup.parse(draft.body)
            let forwardQuote = try? draftDocument?.select(".\(Constants.forwardQuoteHTMLClass) > blockquote").first()?.text()
                .trimmed

            let forwardDocument = try? SwiftSoup.parse(forwardBody)
            let forwardText = try? forwardDocument?.text().trimmed

            if forwardText != forwardQuote {
                return false
            }
        }

        return true
    }
}
