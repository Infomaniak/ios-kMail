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

class NewMessageSheet: SheetState<NewMessageSheet.State> {
    enum State {
        case fileSelection, photoLibrary
    }
}

class NewMessageAlert: SheetState<NewMessageAlert.State> {
    enum State {
        case link(handler: (String) -> Void)
    }
}

struct NewMessageView: View {
    @Binding var isPresented: Bool

    @State private var mailboxManager: MailboxManager
    @State private var selectedMailboxItem = 0
    @State private var draft: UnmanagedDraft
    @State private var editor = RichTextEditorModel()
    @State private var showCc = false
    @FocusState private var focusedRecipientField: RecipientFieldType?
    @State private var addRecipientHandler: ((Recipient) -> Void)?
    @State private var autocompletion: [Recipient] = []
    @State private var sendDisabled = false
    @State private var draftHasChanged = false
    @State private var isShowingCamera = false

    @StateObject private var sheet = NewMessageSheet()
    @StateObject private var alert = NewMessageAlert()

    static var queue = DispatchQueue(label: "com.infomaniak.mail.saveDraft")
    @State var debouncedBufferWrite: DispatchWorkItem?
    let saveExpiration = 3.0

    private var shouldDisplayAutocompletion: Bool {
        return !autocompletion.isEmpty && focusedRecipientField != nil
    }

    init(isPresented: Binding<Bool>, mailboxManager: MailboxManager, draft: UnmanagedDraft? = nil) {
        _isPresented = isPresented
        self.mailboxManager = mailboxManager
        selectedMailboxItem = AccountManager.instance.mailboxes
            .firstIndex { $0.mailboxId == mailboxManager.mailbox.mailboxId } ?? 0
        var initialDraft = draft ?? UnmanagedDraft()
        if let signatureResponse = mailboxManager.getSignatureResponse() {
            if !initialDraft.didSetSignature {
                initialDraft.setSignature(signatureResponse)
                initialDraft.didSetSignature = true
            }
            sendDisabled = false
        } else {
            sendDisabled = true
        }
        initialDraft.delay = UserDefaults.shared.cancelSendDelay.rawValue
        self.draft = initialDraft
    }

    var body: some View {
        NavigationView {
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

                    RichTextEditor(model: $editor, body: $draft.body)
                        .ignoresSafeArea(.all, edges: .bottom)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(
                leading: Button {
                    self.dismiss()
                } label: {
                    Label(MailResourcesStrings.Localizable.buttonClose, systemImage: "xmark")
                },
                trailing: Button {
                    Task {
                        if let cancelableResponse = await send() {
                            IKSnackBar.showCancelableSnackBar(
                                message: MailResourcesStrings.Localizable.emailSentSnackbar,
                                cancelSuccessMessage: MailResourcesStrings.Localizable.canceledEmailSendingConfirmationSnackbar,
                                duration: .custom(CGFloat(draft.delay ?? 3)),
                                cancelableResponse: cancelableResponse,
                                mailboxManager: mailboxManager
                            )
                            self.dismiss()
                        }
                    }
                } label: {
                    Image(resource: MailResourcesAsset.send)
                }
                .disabled(sendDisabled)
            )
            .background(MailResourcesAsset.backgroundColor.swiftUiColor)
        }
        .onChange(of: draft) { _ in
            textDidChange()
        }
        .onChange(of: selectedMailboxItem) { _ in
            let mailbox = AccountManager.instance.mailboxes[selectedMailboxItem]
            guard let mailboxManager = AccountManager.instance.getMailboxManager(for: mailbox),
                  let signatureResponse = mailboxManager.getSignatureResponse() else { return }
            self.mailboxManager = mailboxManager
            draft.setSignature(signatureResponse)
        }
        .onAppear {
            editor.richTextEditor.sheet = sheet
            editor.richTextEditor.alert = alert
            editor.richTextEditor.isShowingCamera = $isShowingCamera
        }
        .onDisappear {
            if draftHasChanged {
                debouncedBufferWrite?.cancel()
                Task {
                    await saveDraft(showSnackBar: true)
                }
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
        .sheet(isPresented: $sheet.isShowing) {
            switch sheet.state {
            case .fileSelection:
                DocumentPicker { urls in
                    Task {
                        await addDocumentAttachment(urls: urls)
                    }
                }
            case .photoLibrary:
                ImagePicker { results in
                    Task {
                        await addImageAttachment(results: results)
                    }
                }
            case .none:
                EmptyView()
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

    @MainActor private func send() async -> CancelableResponse? {
        // Cancel any scheduled save
        debouncedBufferWrite?.cancel()
        do {
            draftHasChanged = false
            return try await mailboxManager.send(draft: draft)
        } catch {
            IKSnackBar.showSnackBar(message: error.localizedDescription)
            return nil
        }
    }

    @MainActor private func saveDraft(showSnackBar: Bool = false) async {
        editor.richTextEditor.getHTML { [self] html in
            Task {
                self.draft.body = html!

                do {
                    let response = try await mailboxManager.save(draft: draft)
                    self.draft.uuid = response.uuid
                    draftHasChanged = false
                    if showSnackBar {
                        IKSnackBar.showSnackBar(message: MailResourcesStrings.Localizable.snackBarDraftSaved,
                                                action: .init(title: MailResourcesStrings.Localizable.actionDelete) {
                                                    deleteDraft(messageUid: response.uid)
                                                })
                    }
                } catch {
                    IKSnackBar.showSnackBar(message: error.localizedDescription)
                }
            }
        }
    }

    private func textDidChange() {
        draftHasChanged = true
        debouncedBufferWrite?.cancel()
        let debouncedWorkItem = DispatchWorkItem {
            Task {
                await saveDraft()
            }
        }
        NewMessageView.queue.asyncAfter(deadline: .now() + saveExpiration, execute: debouncedWorkItem)
        debouncedBufferWrite = debouncedWorkItem
    }

    private func dismiss() {
        isPresented = false
    }

    private func shouldDisplay(field: RecipientFieldType) -> Bool {
        return !shouldDisplayAutocompletion || focusedRecipientField == field
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

    @ViewBuilder
    private func recipientCell(type: RecipientFieldType) -> some View {
        if shouldDisplay(field: type) {
            NewMessageCell(title: type.title, showCc: type == .to ? $showCc : nil) {
                RecipientField(recipients: binding(for: type),
                               autocompletion: $autocompletion,
                               addRecipientHandler: $addRecipientHandler,
                               focusedField: _focusedRecipientField,
                               type: type)
            }
        }
    }

    private func deleteDraft(messageUid: String) {
        // Convert draft to thread
        let realm = mailboxManager.getRealm()
        guard let draft = mailboxManager.draft(messageUid: messageUid, using: realm)?.freeze(),
              let draftFolder = mailboxManager.getFolder(with: .draft, using: realm) else { return }
        let thread = Thread(draft: draft)
        try? realm.safeWrite {
            realm.add(thread, update: .modified)
            draftFolder.threads.insert(thread)
        }
        let frozenThread = thread.freeze()
        // Delete
        Task {
            await tryOrDisplayError {
                _ = try await mailboxManager.move(thread: frozenThread, to: .trash)
                IKSnackBar.showSnackBar(message: MailResourcesStrings.Localizable.snackBarDraftDeleted)
            }
        }
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

    func addImageAttachment(
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

    func addCameraAttachment(
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

    func loadFileRepresentation(_ itemProvider: NSItemProvider, typeIdentifier: String) async throws -> URL {
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

    public nonisolated func getDefaultFileName() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmssSS"
        return formatter.string(from: Date())
    }

    func sendAttachment(url: URL,
                        typeIdentifier: String,
                        name: String,
                        disposition: AttachmentDisposition) async throws -> Attachment? {
        let data = try Data(contentsOf: url)

        return try await sendAttachment(from: data, typeIdentifier: typeIdentifier, name: name, disposition: disposition)
    }

    func sendAttachment(from data: Data,
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

    func addAttachment(_ attachment: Attachment) {
        if draft.attachments == nil {
            draft.attachments = [attachment]
        } else {
            draft.attachments?.append(attachment)
        }
    }
}

struct NewMessageView_Previews: PreviewProvider {
    static var previews: some View {
        NewMessageView(
            isPresented: .constant(true),
            mailboxManager: PreviewHelper.sampleMailboxManager
        )
    }
}
