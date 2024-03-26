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

struct ComposeMessageIntentView: View, IntentViewable {
    typealias Intent = ResolvedIntent

    struct ResolvedIntent {
        let mailboxManager: MailboxManager
        let draft: Draft
        let messageReply: MessageReply?
    }

    @LazyInjectService private var accountManager: AccountManager
    @LazyInjectService private var snackbarPresenter: SnackBarPresentable

    @Environment(\.dismiss) private var dismiss

    @State private var composeMessageIntent: ComposeMessageIntent
    let resolvedIntent = State<ResolvedIntent?>()
    var textAttachment: TextAttachable?
    var attachments: [Attachable]

    init(composeMessageIntent: ComposeMessageIntent, textAttachment: TextAttachable? = nil, attachments: [Attachable] = []) {
        _composeMessageIntent = State(wrappedValue: composeMessageIntent)
        self.textAttachment = textAttachment
        self.attachments = attachments
    }

    var body: some View {
        if composeMessageIntent.shouldSelectMailbox {
            CurrentComposeMailboxView(composeMessageIntent: $composeMessageIntent)
        } else {
            NavigationView {
                if let resolvedIntent = resolvedIntent.wrappedValue {
                    ComposeMessageView(
                        draft: resolvedIntent.draft,
                        mailboxManager: resolvedIntent.mailboxManager,
                        messageReply: resolvedIntent.messageReply,
                        attachments: attachments
                    )
                    .environmentObject(resolvedIntent.mailboxManager)
                } else {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .task {
                            await initFromIntent()
                        }
                }
            }
        }
    }

    func initFromIntent() async {
        guard let mailboxId = composeMessageIntent.mailboxId, let userId = composeMessageIntent.userId,
              let mailboxManager = accountManager.getMailboxManager(for: mailboxId, userId: userId) else {
            dismiss()
            snackbarPresenter.show(message: MailError.unknownError.errorDescription ?? "")
            return
        }

        var draftToWrite: Draft?
        var maybeMessageReply: MessageReply?
        switch composeMessageIntent.type {
        case .new:
            draftToWrite = Draft(localUUID: UUID().uuidString)
        case .existing(let existingDraftLocalUUID):
            draftToWrite = mailboxManager.draft(localUuid: existingDraftLocalUUID)
        case .existingRemote(let messageUid):
            draftToWrite = Draft(messageUid: messageUid)
        case .mailTo(let mailToURLComponents):
            draftToWrite = Draft.mailTo(urlComponents: mailToURLComponents)
        case .writeTo(let recipient):
            draftToWrite = Draft.writing(to: recipient)
        case .reply(let messageUid, let replyMode):
            if let frozenMessage = mailboxManager.getRealm().object(ofType: Message.self, forPrimaryKey: messageUid)?.freeze() {
                let messageReply = MessageReply(frozenMessage: frozenMessage, replyMode: replyMode)
                maybeMessageReply = messageReply
                draftToWrite = Draft.replying(
                    reply: messageReply,
                    currentMailboxEmail: mailboxManager.mailbox.email
                )
            }
        }

        if composeMessageIntent.isFromOutsideOfApp {
            try? await mailboxManager.refreshAllSignatures()
        }

        if let draftToWrite {
            let draftLocalUUID = draftToWrite.localUUID
            writeDraftToRealm(mailboxManager.getRealm(), draft: draftToWrite)

            Task { @MainActor [maybeMessageReply] in
                guard let liveDraft = mailboxManager.draft(localUuid: draftLocalUUID) else {
                    dismiss()
                    snackbarPresenter.show(message: MailError.localMessageNotFound.errorDescription ?? "")
                    return
                }

                resolvedIntent.wrappedValue = ResolvedIntent(
                    mailboxManager: mailboxManager,
                    draft: liveDraft,
                    messageReply: maybeMessageReply
                )
            }
        } else {
            dismiss()
            snackbarPresenter.show(message: MailError.localMessageNotFound.errorDescription ?? "")
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
        composeMessageIntent: .new(originMailboxManager: PreviewHelper.sampleMailboxManager), textAttachment: nil, attachments: []
    )
}
