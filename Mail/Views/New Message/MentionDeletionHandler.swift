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
import InfomaniakCoreCommonUI
import MailCore
import OSLog
import RealmSwift
import WebKit
import InfomaniakDI

final class MentionDeletionHandler: NSObject, WKScriptMessageHandler {
    static let messageName = "mentionsDelete"

    private let draft: Draft

    init(draft: Draft) {
        self.draft = draft
        super.init()
    }

    func userContentController(
        _: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        @InjectService var matomo: MatomoUtils
        guard message.name == Self.messageName,
              let stringBody = message.body as? String,
              let data = stringBody.data(using: .utf8)
        else { return }

        do {
            let refs: [String] = try JSONDecoder().decode([String].self, from: data)

            Task { @MainActor in
                if let liveDraft = draft.thaw() {
                    try? liveDraft.realm?.write {
                        for ref in refs {
                            if let index = liveDraft.mentions.index(of: ref) {
                                liveDraft.mentions.remove(at: index)
                                matomo.track(eventWithCategory: .newMessage, name: "removeMention")
                            }
                        }
                    }
                }
            }
        } catch {
            Logger.general.error("Failed to decode mentionsDelete message: \(error)")
        }
    }
}
