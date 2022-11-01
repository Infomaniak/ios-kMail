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
import Introspect
import MailCore
import MailResources
import PhotosUI
import RealmSwift
import SwiftUI

enum RecipientFieldType: Hashable {
    case to, cc, bcc

    var title: String {
        switch self {
        case .to:
            return MailResourcesStrings.Localizable.toTitle
        case .cc:
            return MailResourcesStrings.Localizable.ccTitle
        case .bcc:
            return MailResourcesStrings.Localizable.bccTitle
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

    @State private var mailboxManager: MailboxManager
    @State private var selectedMailboxItem = 0
    @State private var draft: UnmanagedDraft
    @State private var originalBody: String
    @State private var editor = RichTextEditorModel()
    @State private var showCc = false
    @FocusState private var focusedRecipientField: RecipientFieldType?
    @State private var addRecipientHandler: ((Recipient) -> Void)?
    @State private var autocompletion: [Recipient] = []
    @State private var isShowingCamera = false
    @State private var isShowingFileSelection = false
    @State private var isShowingPhotoLibrary = false

    @State var scrollView: UIScrollView?

    @StateObject private var alert = NewMessageAlert()

    private let sendDisabled: Bool

    private var shouldDisplayAutocompletion: Bool {
        return !autocompletion.isEmpty && focusedRecipientField != nil
    }

    private init(mailboxManager: MailboxManager, draft: UnmanagedDraft) {
        _mailboxManager = State(initialValue: mailboxManager)
        let currentAccountSelectedMailboxItem = AccountManager.instance.mailboxes
            .firstIndex { $0.mailboxId == mailboxManager.mailbox.mailboxId } ?? 0
        _selectedMailboxItem = State(initialValue: currentAccountSelectedMailboxItem)

        var initialDraft = draft
        if initialDraft.identityId.isEmpty,
           let signature = mailboxManager.getSignatureResponse() {
            initialDraft.setSignature(signature)
        }
        sendDisabled = mailboxManager.getSignatureResponse() == nil
        initialDraft.delay = UserDefaults.shared.cancelSendDelay.rawValue
        _draft = State(initialValue: initialDraft)
        _showCc = State(initialValue: !initialDraft.bcc.isEmpty || !initialDraft.cc.isEmpty)
        _originalBody = State(initialValue: initialDraft.body)
    }

    static func newMessage(mailboxManager: MailboxManager) -> ComposeMessageView {
        return ComposeMessageView(mailboxManager: mailboxManager, draft: .empty())
    }

    static func replyOrForwardMessage(messageReply: MessageReply, mailboxManager: MailboxManager) -> ComposeMessageView {
        let message = messageReply.message
        // If message doesn't exist anymore try to show the frozen one
        let realm = mailboxManager.getRealm()
        realm.refresh()
        let freshMessage = message.fresh(using: realm) ?? message
        return ComposeMessageView(mailboxManager: mailboxManager, draft: .replying(to: freshMessage, mode: messageReply.replyMode))
    }

    static func editDraft(draft: Draft, mailboxManager: MailboxManager) -> ComposeMessageView {
        return ComposeMessageView(mailboxManager: mailboxManager, draft: draft.asUnmanaged())
    }

    static func writingTo(recipient: Recipient, mailboxManager: MailboxManager) -> ComposeMessageView {
        return ComposeMessageView(mailboxManager: mailboxManager, draft: .writing(to: recipient))
    }

    static func mailTo(urlComponents: URLComponents, mailboxManager: MailboxManager) -> ComposeMessageView {
        let draft = UnmanagedDraft.mailTo(subject: urlComponents.getQueryItem(named: "subject"),
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
                        NewMessageCell(title: MailResourcesStrings.Localizable.fromTitle, isFirstCell: true) {
                            Picker("Mailbox", selection: $selectedMailboxItem) {
                                ForEach(AccountManager.instance.mailboxes.indices, id: \.self) { i in
                                    Text(AccountManager.instance.mailboxes[i].email).tag(i)
                                }
                            }
                            .textStyle(.body)
                            Spacer()
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
                            addRecipientHandler?(recipient)
                        }
                    } else {
                        NewMessageCell(title: MailResourcesStrings.Localizable.subjectTitle) {
                            TextField("", text: $draft.subject)
                        }

                        if let attachments = draft.attachments?.filter { $0.contentId == nil }, !attachments.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(attachments) { attachment in
                                        AttachmentCell(attachment: attachment)
                                    }
                                }
                                .padding(.vertical, 1)
                            }
                            .padding(.horizontal, 16)
                        }
                        RichTextEditor(model: $editor,
                                       body: $draft.body,
                                       alert: $alert,
                                       isShowingCamera: $isShowingCamera,
                                       isShowingFileSelection: $isShowingFileSelection,
                                       isShowingPhotoLibrary: $isShowingPhotoLibrary)
                            .ignoresSafeArea(.all, edges: .bottom)
                            .frame(height: editor.height + 20)
                            .padding([.vertical], 10)
                    }
                }
            }
            .introspectScrollView { scrollView in
                self.scrollView = scrollView
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
                leading: Button(action: dismiss.callAsFunction) {
                    Label(MailResourcesStrings.Localizable.buttonClose, systemImage: "xmark")
                },
                trailing: Button(action: {
                    originalBody = draft.body
                    Task {
                        await DraftManager.shared.send(draft: draft, mailboxManager: mailboxManager)
                        dismiss()
                    }
                }, label: {
                    Image(resource: MailResourcesAsset.send)
                })
                .disabled(sendDisabled)
            )
            .background(MailResourcesAsset.backgroundColor.swiftUiColor)
        }
        .onChange(of: draft) { _ in
            Task {
                let newDraftUUID = await DraftManager.shared.saveDraftIfNeeded(draft: draft, mailboxManager: mailboxManager)
                draft.uuid = newDraftUUID
            }
        }
        .onChange(of: selectedMailboxItem) { _ in
            let mailbox = AccountManager.instance.mailboxes[selectedMailboxItem]
            guard let mailboxManager = AccountManager.instance.getMailboxManager(for: mailbox),
                  let signatureResponse = mailboxManager.getSignatureResponse() else { return }
            self.mailboxManager = mailboxManager
            draft.setSignature(signatureResponse)
        }
        .onDisappear {
            guard draft.body != originalBody || !draft.uuid.isEmpty else { return }
            Task {
                await DraftManager.shared.saveDraftIfNeeded(draft: draft, mailboxManager: mailboxManager, force: true)
            }
        }
        .fullScreenCover(isPresented: $isShowingCamera) {
            CameraPicker { data in
                Task {
                    await addCameraAttachment(data: data)
                }
            }
            .ignoresSafeArea()
        }
        .sheet(isPresented: $isShowingFileSelection) {
            DocumentPicker { urls in
                Task {
                    await addDocumentAttachment(urls: urls)
                }
            }
        }
        .sheet(isPresented: $isShowingPhotoLibrary) {
            ImagePicker { results in
                Task {
                    await addImageAttachment(results: results)
                }
            }
        }
        .customAlert(isPresented: $alert.isShowing) {
            switch alert.state {
            case let .link(handler):
                AddLinkView(state: alert, actionHandler: handler)
            case .none:
                EmptyView()
            }
        }
        .navigationViewStyle(.stack)
        .defaultAppStorage(.shared)
    }

    @ViewBuilder
    private func recipientCell(type: RecipientFieldType) -> some View {
        let shouldDisplayField = !shouldDisplayAutocompletion || focusedRecipientField == type
        if shouldDisplayField {
            NewMessageCell(title: type.title, showCc: type == .to ? $showCc : nil) {
                RecipientField(recipients: binding(for: type),
                               autocompletion: $autocompletion,
                               addRecipientHandler: $addRecipientHandler,
                               focusedField: _focusedRecipientField,
                               type: type)
            }
        }
    }

    private func binding(for type: RecipientFieldType) -> Binding<[Recipient]> {
        let binding: Binding<[Recipient]>
        switch type {
        case .to:
            binding = $draft.to
        case .cc:
            binding = $draft.cc
        case .bcc:
            binding = $draft.bcc
        }
        return binding
    }

    // MARK: Attachments

    func addDocumentAttachment(urls: [URL]) async {
        await withTaskGroup(of: Void.self) { group in
            for url in urls {
                group.addTask {
                    do {
                        let typeIdentifier = try url.resourceValues(forKeys: [.typeIdentifierKey]).typeIdentifier ?? ""

                        _ = try await self.sendAttachment(
                            url: url,
                            typeIdentifier: typeIdentifier,
                            name: url.lastPathComponent,
                            disposition: .attachment
                        )

                    } catch {
                        print("Error while creating attachment: \(error.localizedDescription)")
                    }
                }
            }
        }
    }

    private func addImageAttachment(
        results: [PHPickerResult],
        disposition: AttachmentDisposition = .attachment,
        completion: @escaping (String) -> Void = { _ in
            // TODO: - Manage inline attachment
        }
    ) async {
        let itemProviders = results.map(\.itemProvider)
        await withTaskGroup(of: Void.self) { group in
            for itemProvider in itemProviders {
                group.addTask {
                    do {
                        let typeIdentifier = itemProvider.registeredTypeIdentifiers.first ?? ""
                        let url = try await self.loadFileRepresentation(itemProvider, typeIdentifier: typeIdentifier)
                        let name = itemProvider.suggestedName ?? self.getDefaultFileName()

                        let attachment = try await self.sendAttachment(
                            url: url,
                            typeIdentifier: typeIdentifier,
                            name: name,
                            disposition: disposition
                        )
                        if disposition == .inline, let cid = attachment?.contentId {
                            completion(cid)
                        }
                    } catch {
                        print("Error while creating attachment: \(error.localizedDescription)")
                    }
                }
            }
        }
    }

    private func addCameraAttachment(
        data: Data,
        disposition: AttachmentDisposition = .attachment,
        completion: @escaping (String) -> Void = { _ in
            // TODO: - Manage inline attachment
        }
    ) async {
        do {
            let typeIdentifier = "public.jpeg"
            let name = getDefaultFileName()

            let attachment = try await sendAttachment(
                from: data,
                typeIdentifier: typeIdentifier,
                name: name,
                disposition: disposition
            )

            if disposition == .inline, let cid = attachment?.contentId {
                completion(cid)
            }
        } catch {
            print("Error while creating attachment: \(error.localizedDescription)")
        }
    }

    private func loadFileRepresentation(_ itemProvider: NSItemProvider, typeIdentifier: String) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            itemProvider.loadFileRepresentation(forTypeIdentifier: typeIdentifier) { url, error in
                if let url = url {
                    continuation.resume(returning: url)
                } else {
                    continuation.resume(throwing: error ?? MailError.unknownError)
                }
            }
        }
    }

    private nonisolated func getDefaultFileName() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmssSS"
        return formatter.string(from: Date())
    }

    private func sendAttachment(url: URL,
                                typeIdentifier: String,
                                name: String,
                                disposition: AttachmentDisposition) async throws -> Attachment? {
        let data = try Data(contentsOf: url)

        return try await sendAttachment(from: data, typeIdentifier: typeIdentifier, name: name, disposition: disposition)
    }

    private func sendAttachment(from data: Data,
                                typeIdentifier: String,
                                name: String,
                                disposition: AttachmentDisposition) async throws -> Attachment? {
        let uti = UTType(typeIdentifier)
        var name = name
        if let nameExtension = uti?.preferredFilenameExtension, !name.capitalized.hasSuffix(nameExtension.capitalized) {
            name.append(".\(nameExtension)")
        }

        let attachment = try await mailboxManager.apiFetcher.createAttachment(
            mailbox: mailboxManager.mailbox,
            attachmentData: data,
            disposition: disposition,
            attachmentName: name,
            mimeType: uti?.preferredMIMEType ?? "application/octet-stream"
        )
        addAttachment(attachment)
        return attachment
    }

    private func addAttachment(_ attachment: Attachment) {
        if draft.attachments == nil {
            draft.attachments = [attachment]
        } else {
            draft.attachments?.append(attachment)
        }
    }
}

struct NewMessageView_Previews: PreviewProvider {
    static var previews: some View {
        ComposeMessageView.newMessage(mailboxManager: PreviewHelper.sampleMailboxManager)
    }
}
