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
    @LazyInjectService private var draftManager: DraftManager

    @State private var isLoadingContent = true
    @State private var isShowingCancelAttachmentsError = false
    @State private var autocompletionType: ComposeViewFieldType?
    @State private var editorFocus = false

    @State private var editorModel = RichTextEditorModel()
    @State private var scrollView: UIScrollView?

    @StateObject private var attachmentsManager: AttachmentsManager
    @StateObject private var alert = NewMessageAlert()

    @StateRealmObject private var draft: Draft

    @FocusState private var focusedField: ComposeViewFieldType? {
        willSet {
            let editorInFocus = (newValue == .editor)
            editorFocus = editorInFocus
        }
    }

    private let messageReply: MessageReply?
    private let draftContentManager: DraftContentManager
    private let mailboxManager: MailboxManager

    private var isSendButtonDisabled: Bool {
        let disabledState = draft.identityId == nil
            || draft.identityId?.isEmpty == true
            || draft.recipientsAreEmpty
            || !attachmentsManager.allAttachmentsUploaded
        return disabledState
    }

    // MARK: - Init

    init(draft: Draft, mailboxManager: MailboxManager, messageReply: MessageReply? = nil) {
        self.messageReply = messageReply

        Self.saveNewDraftInRealm(mailboxManager.getRealm(), draft: draft)
        _draft = StateRealmObject(wrappedValue: draft)

        draftContentManager = DraftContentManager(
            incompleteDraft: draft,
            messageReply: messageReply,
            mailboxManager: mailboxManager
        )

        self.mailboxManager = mailboxManager
        _attachmentsManager = StateObject(wrappedValue: AttachmentsManager(draft: draft, mailboxManager: mailboxManager))
    }

    // MARK: - View

    var body: some View {
        NavigationView {
            composeMessage
        }
        .task {
            do {
                isLoadingContent = true
                try await draftContentManager.prepareCompleteDraft()
                attachmentsManager.completeUploadedAttachments()
                isLoadingContent = false
            } catch {
                // Unable to get signatures, "An error occurred" and close modal.
                IKSnackBar.showSnackBar(message: MailError.unknownError.localizedDescription)
                dismiss()
            }
        }
        .onAppear {
            switch messageReply?.replyMode {
            case .reply, .replyAll:
                focusedField = .editor
            default:
                focusedField = .to
            }
        }
        .onDisappear {
            draftManager.syncDraft(mailboxManager: mailboxManager)
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

                if autocompletionType == nil && !isLoadingContent {
                    ComposeMessageBodyView(
                        draft: draft,
                        editorModel: $editorModel,
                        editorFocus: $editorFocus,
                        attachmentsManager: attachmentsManager,
                        alert: alert,
                        dismiss: dismiss,
                        messageReply: messageReply
                    )
                }
            }
        }
        .background(MailResourcesAsset.backgroundColor.swiftUIColor)
        .overlay {
            if isLoadingContent {
                progressView
            }
        }
        .introspectScrollView { scrollView in
            guard self.scrollView != scrollView else { return }
            self.scrollView = scrollView
            scrollView.keyboardDismissMode = .interactive
        }
        .onChange(of: editorModel.height) { _ in
            guard let scrollView else { return }

            let fullSize = scrollView.contentSize.height
            let realPosition = (fullSize - editorModel.height) + editorModel.cursorPosition

            guard realPosition >= 0 else { return }
            let rect = CGRect(x: 0, y: realPosition, width: 1, height: 1)
            scrollView.scrollRectToVisible(rect, animated: true)
        }
        .onChange(of: autocompletionType) { newValue in
            guard newValue != nil else { return }

            let rectTop = CGRect(x: 0, y: 0, width: 1, height: 1)
            scrollView?.scrollRectToVisible(rectTop, animated: true)
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

    // MARK: - Func

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
        ComposeMessageView.newMessage(Draft(), mailboxManager: PreviewHelper.sampleMailboxManager)
    }
}
