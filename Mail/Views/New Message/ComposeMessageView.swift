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
import Introspect
import MailCore
import MailResources
import RealmSwift
import SwiftUI

enum ComposeViewFieldType: Hashable {
    case from, to, cc, bcc, subject, editor, autocomplete
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
        case .autocomplete:
            return "autocomplete"
        }
    }
}

final class NewMessageAlert: SheetState<NewMessageAlert.State> {
    enum State {
        case link(handler: (String) -> Void)
        case emptySubject(handler: () -> Void)
    }
}

struct ComposeMessageView: View {
    @Environment(\.dismiss) private var dismiss

    @LazyInjectService private var matomo: MatomoUtils

    @State private var isLoadingContent: Bool
    @State private var isShowingCancelAttachmentsError = false
    @State private var autocompletionType: ComposeViewFieldType?
    @State private var editorFocus = false

    /// Something to track the initial loading of a default signature
    @StateObject private var signatureManager: SignaturesManager
    @StateObject private var mailboxManager: MailboxManager
    @StateObject private var attachmentsManager: AttachmentsManager
    @StateObject private var alert = NewMessageAlert()

    @StateRealmObject private var draft: Draft

    @FocusState private var focusedField: ComposeViewFieldType? {
        willSet {
            let editorInFocus = (newValue == .editor)
            editorFocus = editorInFocus
        }
    }

    let messageReply: MessageReply?

    private var isSendButtonDisabled: Bool {
        let disabledState = draft.identityId == nil
        || draft.identityId?.isEmpty == true
        || draft.recipientsAreEmpty
        || !attachmentsManager.allAttachmentsUploaded
        return disabledState
    }

    // MAK: - Int

    init(draft: Draft, mailboxManager: MailboxManager, messageReply: MessageReply? = nil) {
        self.messageReply = messageReply

        Self.saveNewDraftInRealm(mailboxManager.getRealm(), draft: draft)
        _draft = StateRealmObject(wrappedValue: draft)

        _isLoadingContent = State(wrappedValue: (draft.messageUid != nil && draft.remoteUUID.isEmpty) || messageReply != nil)

        _signatureManager = StateObject(wrappedValue: SignaturesManager(mailboxManager: mailboxManager))
        _mailboxManager = StateObject(wrappedValue: mailboxManager)
        _attachmentsManager = StateObject(wrappedValue: AttachmentsManager(draft: draft, mailboxManager: mailboxManager))
    }

    // MAK: - View

    var body: some View {
        NavigationView {
            composeMessage
        }
        .interactiveDismissDisabled()
        .customAlert(isPresented: $alert.isShowing) {
            switch alert.state {
            case .link(let handler):
                AddLinkView(actionHandler: handler)
            case .emptySubject(let handler):
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

    /// Compose message view
    private var composeMessage: some View {
        ScrollView {
            VStack(spacing: 0) {
                ComposeMessageHeaderView(draft: draft, focusedField: _focusedField, autocompletionType: $autocompletionType)

                if autocompletionType == nil {
                    ComposeMessageBodyView(
                        draft: draft,
                        isLoadingContent: $isLoadingContent,
                        editorFocus: $editorFocus,
                        attachmentsManager: attachmentsManager,
                        alert: alert,
                        dismiss: dismiss,
                        messageReply: messageReply
                    )
                    .environmentObject(signatureManager)
                }
            }
        }
        .background(MailResourcesAsset.backgroundColor.swiftUIColor)
        .onAppear {
            switch messageReply?.replyMode {
            case .reply, .replyAll:
                focusedField = .editor
            default:
                focusedField = .to
            }
        }
        .onDisappear {
            Task {
                DraftManager.shared.syncDraft(mailboxManager: mailboxManager)
            }
        }
        .overlay {
            if isLoadingContent || signatureManager.loadingSignatureState == .progress {
                progressView
            }
        }
        .introspectScrollView { scrollView in
            scrollView.keyboardDismissMode = .interactive
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
    }

    /// Progress view
    private var progressView: some View {
        ProgressView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(MailResourcesAsset.backgroundColor.swiftUIColor)
    }

    // MAK: - Func

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

struct ComposeMessageView_Previews: PreviewProvider {
    static var previews: some View {
        ComposeMessageView.newMessage(mailboxManager: PreviewHelper.sampleMailboxManager)
    }
}
