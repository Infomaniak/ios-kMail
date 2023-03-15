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

import InfomaniakCore
import InfomaniakCoreUI
import InfomaniakDI
import Introspect
import MailCore
import MailResources
import PhotosUI
import RealmSwift
import SwiftUI

enum ComposeViewFieldType: Hashable {
    case from, to, cc, bcc, subject

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
        }
    }
}

class NewMessageAlert: SheetState<NewMessageAlert.State> {
    enum State {
        case link(handler: (String) -> Void)
    }
}

struct ComposeMessageView: View {
    @Environment(\.dismiss) private var dismiss

    @LazyInjectService private var matomo: MatomoUtils

    @State private var mailboxManager: MailboxManager
    @StateRealmObject var draft: Draft
    @State private var editor = RichTextEditorModel()
    @State private var showCc = false
    @FocusState private var focusedField: ComposeViewFieldType?
    @State private var addRecipientHandler: ((Recipient) -> Void)?
    @State private var autocompletion: [Recipient] = []
    @State private var isShowingCamera = false
    @State private var isShowingFileSelection = false
    @State private var isShowingPhotoLibrary = false
    @StateObject private var attachmentsManager: AttachmentsManager
    @State private var isShowingCancelAttachmentsError = false

    @State var scrollView: UIScrollView?

    @StateObject private var alert = NewMessageAlert()

    private var isSendButtonDisabled: Bool {
        return draft.identityId?.isEmpty == true
            || (draft.to.isEmpty && draft.cc.isEmpty && draft.bcc.isEmpty)
            || !attachmentsManager.allAttachmentsUploaded
    }

    private var shouldDisplayAutocompletion: Bool {
        return !autocompletion.isEmpty && focusedField != nil
    }

    private init(mailboxManager: MailboxManager, draft: Draft) {
        _mailboxManager = State(initialValue: mailboxManager)
        if draft.identityId == nil || draft.identityId?.isEmpty == true,
           let signature = mailboxManager.getSignatureResponse() {
            draft.setSignature(signature)
        }
        let realm = mailboxManager.getRealm()
        try? realm.write {
            draft.action = draft.action == nil && draft.remoteUUID.isEmpty ? .initialSave : .save
            draft.delay = UserDefaults.shared.cancelSendDelay.rawValue

            realm.add(draft, update: .modified)
        }

        _draft = StateRealmObject(wrappedValue: draft)
        _showCc = State(initialValue: !draft.bcc.isEmpty || !draft.cc.isEmpty)
        _attachmentsManager = StateObject(wrappedValue: AttachmentsManager(draft: draft, mailboxManager: mailboxManager))
    }

    static func newMessage(mailboxManager: MailboxManager) -> ComposeMessageView {
        return ComposeMessageView(mailboxManager: mailboxManager, draft: Draft(localUUID: UUID().uuidString))
    }

    static func replyOrForwardMessage(messageReply: MessageReply, mailboxManager: MailboxManager) -> ComposeMessageView {
        let message = messageReply.message
        // If message doesn't exist anymore try to show the frozen one
        let freshMessage = message.thaw() ?? message
        return ComposeMessageView(
            mailboxManager: mailboxManager,
            draft: .replying(to: freshMessage, mode: messageReply.replyMode, localDraftUUID: messageReply.localDraftUUID)
        )
    }

    static func editDraft(draft: Draft, mailboxManager: MailboxManager) -> ComposeMessageView {
        @InjectService var matomo: MatomoUtils
        matomo.track(eventWithCategory: .newMessage, name: "openFromDraft")
        return ComposeMessageView(mailboxManager: mailboxManager, draft: draft)
    }

    static func writingTo(recipient: Recipient, mailboxManager: MailboxManager) -> ComposeMessageView {
        return ComposeMessageView(mailboxManager: mailboxManager, draft: .writing(to: recipient))
    }

    static func mailTo(urlComponents: URLComponents, mailboxManager: MailboxManager) -> ComposeMessageView {
        let draft = Draft.mailTo(subject: urlComponents.getQueryItem(named: "subject"),
                                 body: urlComponents.getQueryItem(named: "body"),
                                 to: [Recipient(email: urlComponents.path, name: "")],
                                 cc: Recipient.createListUsing(from: urlComponents, name: "cc"),
                                 bcc: Recipient.createListUsing(from: urlComponents, name: "bcc"))
        return ComposeMessageView(mailboxManager: mailboxManager, draft: draft)
    }

    var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 0) {
                    if !shouldDisplayAutocompletion {
                        NewMessageCell(type: .from,
                                       isFirstCell: true) {
                            Text(mailboxManager.mailbox.email)
                                .textStyle(.body)
                        }
                    }

                    recipientCell(type: .to)

                    if showCc {
                        recipientCell(type: .cc)
                        recipientCell(type: .bcc)
                    }

                    // Show the rest of the view, or the autocompletion list
                    if shouldDisplayAutocompletion {
                        AutocompletionView(autocompletion: $autocompletion) { recipient in
                            matomo.track(eventWithCategory: .newMessage, name: "addNewRecipient")
                            addRecipientHandler?(recipient)
                        }
                    } else {
                        NewMessageCell(type: .subject,
                                       focusedField: _focusedField) {
                            TextField("", text: $draft.subject)
                                .focused($focusedField, equals: .subject)
                        }

                        AttachmentsHeaderView(attachmentsManager: attachmentsManager)

                        RichTextEditor(model: $editor,
                                       body: $draft.body,
                                       alert: $alert,
                                       isShowingCamera: $isShowingCamera,
                                       isShowingFileSelection: $isShowingFileSelection,
                                       isShowingPhotoLibrary: $isShowingPhotoLibrary,
                                       matomo: matomo)
                            .ignoresSafeArea(.all, edges: .bottom)
                            .frame(height: editor.height + 20)
                            .padding([.vertical], 10)
                    }
                }
            }
            .overlay {
                if draft.messageUid != nil && draft.remoteUUID.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(MailResourcesAsset.backgroundColor.swiftUiColor)
                }
            }
            .introspectScrollView { scrollView in
                self.scrollView = scrollView
                scrollView.keyboardDismissMode = .interactive
            }
            .onChange(of: editor.height) { _ in
                guard let scrollView = scrollView else { return }

                let fullSize = scrollView.contentSize.height
                let realPosition = (fullSize - editor.height) + editor.cursorPosition

                let rect = CGRect(x: 0, y: realPosition, width: 1, height: 1)
                scrollView.scrollRectToVisible(rect, animated: true)
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(
                leading: Button(action: closeDraft) {
                    Label(MailResourcesStrings.Localizable.buttonClose, systemImage: "xmark")
                },
                trailing: Button(action: sendDraft) {
                    Image(resource: MailResourcesAsset.send)
                }
                .disabled(isSendButtonDisabled)
            )
            .background(MailResourcesAsset.backgroundColor.swiftUiColor)
        }
        .onAppear {
            focusedField = .to
        }
        .onDisappear {
            Task {
                DraftManager.shared.syncDraft(mailboxManager: mailboxManager)
            }
        }
        .interactiveDismissDisabled()
        .fullScreenCover(isPresented: $isShowingCamera) {
            CameraPicker { data in
                attachmentsManager.importAttachments(attachments: [data])
            }
            .ignoresSafeArea()
        }
        .sheet(isPresented: $isShowingFileSelection) {
            DocumentPicker { urls in
                attachmentsManager.importAttachments(attachments: urls)
            }
        }
        .sheet(isPresented: $isShowingPhotoLibrary) {
            ImagePicker { results in
                attachmentsManager.importAttachments(attachments: results)
            }
        }
        .customAlert(isPresented: $alert.isShowing) {
            switch alert.state {
            case let .link(handler):
                AddLinkView(actionHandler: handler)
            case .none:
                EmptyView()
            }
        }
        .customAlert(isPresented: $isShowingCancelAttachmentsError) {
            AttachmentsUploadInProgressErrorView {
                dismiss()
            }
        }
        .task {
            guard draft.messageUid != nil && draft.remoteUUID.isEmpty else { return }

            do {
                if let fetchedDraft = try await mailboxManager.draft(partialDraft: draft),
                   let liveFetchedDraft = fetchedDraft.thaw() {
                    self.draft = liveFetchedDraft
                }
            } catch {
                // Fail silently
            }
        }
        .navigationViewStyle(.stack)
        .defaultAppStorage(.shared)
        .matomoView(view: ["ComposeMessage"])
    }

    @ViewBuilder
    private func recipientCell(type: ComposeViewFieldType) -> some View {
        let shouldDisplayField = !shouldDisplayAutocompletion || focusedField == type
        if shouldDisplayField {
            NewMessageCell(type: type,
                           focusedField: _focusedField,
                           showCc: type == .to ? $showCc : nil) {
                RecipientField(recipients: binding(for: type),
                               autocompletion: $autocompletion,
                               addRecipientHandler: $addRecipientHandler,
                               focusedField: _focusedField,
                               type: type,
                               matomo: matomo)
            }
        }
    }

    private func binding(for type: ComposeViewFieldType) -> Binding<RealmSwift.List<Recipient>> {
        let binding: Binding<RealmSwift.List<Recipient>>
        switch type {
        case .to:
            binding = $draft.to
        case .cc:
            binding = $draft.cc
        case .bcc:
            binding = $draft.bcc
        default:
            fatalError("Unhandled binding \(type)")
        }
        return binding
    }

    private func closeDraft() {
        guard attachmentsManager.allAttachmentsUploaded else {
            isShowingCancelAttachmentsError = true
            return
        }

        dismiss()
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
}

struct NewMessageView_Previews: PreviewProvider {
    static var previews: some View {
        ComposeMessageView.newMessage(mailboxManager: PreviewHelper.sampleMailboxManager)
    }
}
