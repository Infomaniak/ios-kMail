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

import InfomaniakDI
import MailCore
import NavigationBackport
import RealmSwift
import SwiftUI

struct ComposeMessageIntentView: View {
    @LazyInjectService private var accountManager: AccountManager

    let composeMessageIntent: ComposeMessageIntent

    @State private var draft: Draft?
    @State private var mailboxManager: MailboxManager?
    @State private var messageReply: MessageReply?

    var body: some View {
        NBNavigationStack {
            if let draft,
               let mailboxManager {
                ComposeMessageView(draft: draft, mailboxManager: mailboxManager, messageReply: messageReply)
            } else {
                ProgressView()
                    .progressViewStyle(.circular)
            }
        }
        .interactiveDismissDisabled()
        .task(id: composeMessageIntent) {
            await initFromIntent()
        }
    }

    func initFromIntent() async {
        guard let mailboxManager = accountManager.getMailboxManager(
            for: composeMessageIntent.mailboxId,
            userId: composeMessageIntent.userId
        ) else {
            return
        }

        var draftLocalUUID: String?
        var newDraft: Draft?
        switch composeMessageIntent.type {
        case .new:
            newDraft = Draft(localUUID: UUID().uuidString)
        case .existing(let existingDraftLocalUUID):
            draftLocalUUID = existingDraftLocalUUID
        case .mailTo(let mailToURLComponents):
            newDraft = Draft.mailTo(urlComponents: mailToURLComponents)
        case .writeTo(let recipient):
            newDraft = Draft.writing(to: recipient)
        case .reply(let messageUid, let replyMode):
            if let frozenMessage = mailboxManager.getRealm().object(ofType: Message.self, forPrimaryKey: messageUid)?.freeze() {
                let messageReply = MessageReply(frozenMessage: frozenMessage, replyMode: replyMode)
                self.messageReply = messageReply
                newDraft = Draft.replying(
                    reply: messageReply,
                    currentMailboxEmail: mailboxManager.mailbox.email
                )
            }
        }

        if let newDraft {
            draftLocalUUID = newDraft.localUUID
            writeDraftToRealm(mailboxManager.getRealm(), draft: newDraft)
        }

        guard let draftLocalUUID else { return }

        Task { @MainActor in
            draft = mailboxManager.draft(localUuid: draftLocalUUID)
            self.mailboxManager = mailboxManager
        }
    }

    func writeDraftToRealm(_ realm: Realm, draft: Draft) {
        try? realm.write {
            draft.action = draft.action == nil && draft.remoteUUID.isEmpty ? .initialSave : .save
            draft.delay = UserDefaults.shared.cancelSendDelay.rawValue

            realm.add(draft, update: .modified)
        }
    }
}

#Preview {
    ComposeMessageIntentView(
        composeMessageIntent: .new(originMailboxManager: PreviewHelper.sampleMailboxManager)
    )
}
