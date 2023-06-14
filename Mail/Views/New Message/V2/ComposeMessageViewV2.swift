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

import InfomaniakCoreUI
import InfomaniakDI
import MailCore
import MailResources
import RealmSwift
import SwiftUI

// TODO: Rename without V2

enum ComposeViewFieldType: Hashable {
    case from, to, cc, bcc, subject, editor
    case chip(Int, Recipient)

    var title: String {
        switch self {
        case .from:
            return MailResourcesStrings.Localizable.fromTitle
        case .to:
            return MailResourcesStrings.Localizable.toTitle
        case .cc:
            return MailResourcesStrings.Localizable.ccTitle
        case .bcc:
            return MailResourcesStrings.Localizable.bccTitle
        case .subject:
            return MailResourcesStrings.Localizable.subjectTitle
        case .editor:
            return "editor"
        case .chip:
            return "Recipient Chip"
        }
    }
}

final class NewMessageAlert: SheetState<NewMessageAlert.State> {
    enum State {
        case link(handler: (String) -> Void)
        case emptySubject(handler: () -> Void)
    }
}

struct ComposeMessageViewV2: View {
    @Environment(\.dismiss) private var dismiss

    @LazyInjectService private var matomo: MatomoUtils

    @State private var isLoadingContent: Bool
    @State private var isShowingCancelAttachmentsError = false

    @StateObject private var mailboxManager: MailboxManager
    @StateObject private var attachmentsManager: AttachmentsManager
    @StateObject private var alert = NewMessageAlert()

    @StateRealmObject private var draft: Draft

    let messageReply: MessageReply?

    private var isSendButtonDisabled: Bool {
        return draft.identityId?.isEmpty == true || draft.recipientsAreEmpty || !attachmentsManager.allAttachmentsUploaded
    }

    init(draft: Draft, mailboxManager: MailboxManager, messageReply: MessageReply? = nil) {
        self.messageReply = messageReply

        Self.saveNewDraftInRealm(mailboxManager.getRealm(), draft: draft)
        _draft = StateRealmObject(wrappedValue: draft)

        _isLoadingContent = State(wrappedValue: (draft.messageUid != nil && draft.remoteUUID.isEmpty) || messageReply != nil)

        _mailboxManager = StateObject(wrappedValue: mailboxManager)
        _attachmentsManager = StateObject(wrappedValue: AttachmentsManager(draft: draft, mailboxManager: mailboxManager))
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    ComposeMessageHeaderViewV2(draft: draft)

                    ComposeMessageBodyViewV2(
                        draft: draft,
                        isLoadingContent: $isLoadingContent,
                        attachmentsManager: attachmentsManager,
                        alert: alert,
                        messageReply: messageReply
                    )
                }
            }
            .background(MailResourcesAsset.backgroundColor.swiftUIColor)
            .onDisappear {
                Task {
                    DraftManager.shared.syncDraft(mailboxManager: mailboxManager)
                }
            }
            .navigationTitle(MailResourcesStrings.Localizable.buttonNewMessage)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: didTouchDismiss) {
                        Label(MailResourcesStrings.Localizable.buttonClose, systemImage: "xmark")
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: didTouchSend) {
                        Label(MailResourcesStrings.Localizable.send, image: MailResourcesAsset.send.name)
                    }
                    .disabled(isSendButtonDisabled)
                }
            }
            .customAlert(isPresented: $alert.isShowing) {
                switch alert.state {
                case let .link(handler):
                    AddLinkView(actionHandler: handler)
                case let .emptySubject(handler):
                    EmptySubjectView(actionHandler: handler)
                case .none:
                    EmptyView()
                }
            }
            .customAlert(isPresented: $isShowingCancelAttachmentsError) {
                AttachmentsUploadInProgressErrorView {
                    dismiss()
                }
            }
            .matomoView(view: ["ComposeMessage"])
        }
    }

    private func didTouchDismiss() {
        guard attachmentsManager.allAttachmentsUploaded else {
            isShowingCancelAttachmentsError = true
            return
        }
        dismiss()
    }

    private func didTouchSend() {
        guard !draft.subject.isEmpty else {
            matomo.track(eventWithCategory: .newMessage, name: "sendWithoutSubject")
            alert.state = .emptySubject(handler: sendDraft)
            return
        }
        sendDraft()
    }

    private func sendDraft() {
        matomo.trackSendMessage(numberOfTo: draft.to.count, numberOfCc: draft.cc.count, numberOfBcc: draft.bcc.count)
        if let liveDraft = draft.thaw() {
            try? liveDraft.realm?.write {
                liveDraft.action = .send
            }
        }
        dismiss()
    }

    private static func saveNewDraftInRealm(_ realm: Realm, draft: Draft) {
        try? realm.write {
            draft.action = draft.action == nil && draft.remoteUUID.isEmpty ? .initialSave : .save
            draft.delay = UserDefaults.shared.cancelSendDelay.rawValue

            realm.add(draft, update: .modified)
        }
    }
}

struct ComposeMessageViewV2_Previews: PreviewProvider {
    static var previews: some View {
        ComposeMessageViewV2.newMessage(mailboxManager: PreviewHelper.sampleMailboxManager)
    }
}
