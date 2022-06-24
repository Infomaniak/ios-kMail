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

class NewMessageBottomSheet: BottomSheetState<NewMessageBottomSheet.State, NewMessageBottomSheet.Position> {
    enum State {
        case attachment
        case link(handler: (String) -> Void)
    }

    enum Position: CGFloat, CaseIterable {
        case link = 200, attachment = 250, hidden = 0
    }
}

struct NewMessageView: View {
    @Binding var isPresented: Bool

    @State private var mailboxManager: MailboxManager
    @State private var selectedMailboxItem: Int = 0
    @State private var draft: UnmanagedDraft
    @State private var editor = RichTextEditorModel()
    @State private var showCc = false
    @FocusState private var focusedRecipientField: RecipientFieldType?
    @State private var addRecipientHandler: ((Recipient) -> Void)?
    @State private var autocompletion: [Recipient] = []
    @State private var sendDisabled = false
    @State private var draftHasChanged = false

    @StateObject private var bottomSheet = NewMessageBottomSheet()
    @StateObject private var attachmentSheet = NewMessageAttachmentSheet()

    @State private var image = UIImage()

    static var queue = DispatchQueue(label: "com.infomaniak.mail.saveDraft")
    @State var debouncedBufferWrite: DispatchWorkItem?
    let saveExpiration = 3.0

    private let bottomSheetOptions = Constants.bottomSheetOptions + [.absolutePositionValue]

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
            initialDraft.setSignature(signatureResponse)
            sendDisabled = false
        } else {
            sendDisabled = true
        }
        initialDraft.delay = UserDefaults.shared.cancelSendDelay.rawValue
        self.draft = initialDraft
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 12) {
                if !shouldDisplayAutocompletion {
                    NewMessageCell(title: MailResourcesStrings.Localizable.fromTitle) {
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

                    RichTextEditor(model: $editor, body: $draft.body)
                        .padding(.horizontal, 16)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(
                leading: Button {
                    self.dismiss()
                } label: {
                    Image(systemName: "xmark")
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
            editor.richTextEditor.bottomSheet = bottomSheet
            editor.richTextEditor.attachmentSheet = attachmentSheet
        }
        .onDisappear {
            if draftHasChanged {
                debouncedBufferWrite?.cancel()
                Task {
                    await saveDraft(showSnackBar: true)
                }
            }
        }
        .sheet(isPresented: $attachmentSheet.isShowing) {
            CameraPicker(selectedImage: self.$image)
        }
        .bottomSheet(bottomSheetPosition: $bottomSheet.position, options: bottomSheetOptions) {
            switch bottomSheet.state {
            case .attachment:
                AttachmentView(bottomSheet: bottomSheet)
            case let .link(handler):
                LinkView(actionHandler: handler)
            case .none:
                EmptyView()
            }
        }
        .navigationViewStyle(.stack)
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
}

struct NewMessageView_Previews: PreviewProvider {
    static var previews: some View {
        NewMessageView(
            isPresented: .constant(true),
            mailboxManager: PreviewHelper.sampleMailboxManager
        )
    }
}
