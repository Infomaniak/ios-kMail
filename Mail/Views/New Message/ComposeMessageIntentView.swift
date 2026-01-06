/*
 Infomaniak Mail - iOS App
 Copyright (C) 2024 Infomaniak Network SA

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

import InfomaniakCore
import InfomaniakCoreCommonUI
import InfomaniakCoreDB
import InfomaniakCoreSwiftUI
import InfomaniakDI
import MailCore
import MailCoreUI
import SwiftUI

struct ComposeMessageIntentView: View, IntentViewable {
    typealias Intent = ResolvedIntent

    struct ResolvedIntent {
        let currentUser: UserProfile
        let mailboxManager: MailboxManager
        let draft: Draft
        let messageReply: MessageReply?
        let mainViewState: MainViewState
    }

    @Environment(\.dismiss) private var dismiss

    @State private var composeMessageIntent: ComposeMessageIntent
    let resolvedIntent = State<ResolvedIntent?>()
    var htmlAttachments: [HTMLAttachable] = []
    var attachments: [Attachable] = []

    init(composeMessageIntent: ComposeMessageIntent, htmlAttachments: [HTMLAttachable] = [], attachments: [Attachable] = []) {
        _composeMessageIntent = State(wrappedValue: composeMessageIntent)
        self.htmlAttachments = htmlAttachments
        self.attachments = attachments
    }

    var body: some View {
        Group {
            if composeMessageIntent.shouldSelectMailbox {
                CurrentComposeMailboxView(composeMessageIntent: $composeMessageIntent)
            } else {
                NavigationView {
                    if let resolvedIntent = resolvedIntent.wrappedValue {
                        ComposeMessageView(
                            draft: resolvedIntent.draft,
                            mailboxManager: resolvedIntent.mailboxManager,
                            messageReply: resolvedIntent.messageReply,
                            attachments: attachments,
                            htmlAttachments: htmlAttachments
                        )
                        .navigationBarTitleDisplayMode(.inline)
                        .environmentObject(resolvedIntent.mailboxManager)
                        .environmentObject(resolvedIntent.mainViewState)
                        .environment(\.currentUser, MandatoryEnvironmentContainer(value: resolvedIntent.currentUser))
                    } else {
                        ComposeMessageProgressView()
                            .task {
                                await initFromIntent()
                            }
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
        .interactiveDismissDisabled()
    }

    func initFromIntent() async {
        @InjectService var accountManager: AccountManager
        @InjectService var snackbarPresenter: IKSnackBarPresentable

        guard let mailboxId = composeMessageIntent.mailboxId, let userId = composeMessageIntent.userId,
              let mailboxManager = accountManager.getMailboxManager(for: mailboxId, userId: userId),
              let currentUser = await accountManager.userProfileStore.getUserProfile(id: userId) else {
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
            // TODO: Can we move this transaction away from the main actor ?
            if let frozenMessage = mailboxManager.fetchObject(ofType: Message.self, forPrimaryKey: messageUid)?.freeze() {
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
            writeDraftToRealm(mailboxManager, draft: draftToWrite)

            Task { @MainActor [maybeMessageReply] in
                guard let liveDraft = mailboxManager.draft(localUuid: draftLocalUUID),
                      let mainViewState = await getMainViewState(mailboxManager: mailboxManager)
                else {
                    dismiss()
                    snackbarPresenter.show(message: MailError.localMessageNotFound.errorDescription ?? "")
                    return
                }

                resolvedIntent.wrappedValue = ResolvedIntent(
                    currentUser: currentUser,
                    mailboxManager: mailboxManager,
                    draft: liveDraft,
                    messageReply: maybeMessageReply,
                    mainViewState: mainViewState
                )
            }
        } else {
            dismiss()
            snackbarPresenter.show(message: MailError.localMessageNotFound.errorDescription ?? "")
        }
    }

    func getMainViewState(mailboxManager: MailboxManager) async -> MainViewState? {
        @InjectService var mainViewStateStore: MainViewStateStore
        if let mainViewState = await mainViewStateStore.getExistingMainViewState(for: mailboxManager) {
            return mainViewState
        } else if let inboxFolder = mailboxManager.getFolder(with: .inbox)?.freezeIfNeeded() {
            return await mainViewStateStore.getOrCreateMainViewState(for: mailboxManager, initialFolder: inboxFolder)
        } else {
            return nil
        }
    }

    func writeDraftToRealm(_ transactionable: Transactionable, draft: Draft) {
        try? transactionable.writeTransaction { realm in
            draft.action = draft.action == nil && draft.remoteUUID.isEmpty ? .initialSave : .save
            draft.delay = UserDefaults.shared.cancelSendDelay.safeValue

            realm.add(draft, update: .modified)
        }
    }
}

#Preview {
    ComposeMessageIntentView(
        composeMessageIntent: .new(originMailboxManager: PreviewHelper.sampleMailboxManager), htmlAttachments: [], attachments: []
    )
}
