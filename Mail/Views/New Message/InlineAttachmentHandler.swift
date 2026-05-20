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
import MailCore
import OSLog
import WebKit

final class InlineAttachmentHandler: NSObject, WKScriptMessageHandler {
    private let attachmentsManager: AttachmentsManager

    init(attachmentsManager: AttachmentsManager) {
        self.attachmentsManager = attachmentsManager
        super.init()
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "inlineAttachmentDelete",
              let stringBody = message.body as? String,
              let data = stringBody.data(using: .utf8) else {
            return
        }

        do {
            let cidArray: [String] = try JSONDecoder().decode([String].self, from: data)
            let arrayWithoutPrefix = cidArray.map { $0.replacingOccurrences(of: "cid:", with: "") }

            Task { @MainActor in
                for cid in arrayWithoutPrefix {
                    if let attachment = attachmentsManager.liveAttachments.first(where: { $0.contentId == cid }) {
                        attachmentsManager.removeAttachment(attachment.uuid)
                    }
                }
            }
        } catch {
            Logger.general.error("Failed to decode inlineAttachmentDelete message: \(error)")
            return
        }
    }
}
