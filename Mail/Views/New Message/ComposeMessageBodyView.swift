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
import MailCore
import RealmSwift
import SwiftUI

struct ComposeMessageBodyView: View {
    @EnvironmentObject private var mailboxManager: MailboxManager

    /// Something to track the initial loading of a default signature
    @EnvironmentObject private var signatureManager: SignaturesManager

    @State private var isShowingCamera = false
    @State private var isShowingFileSelection = false
    @State private var isShowingPhotoLibrary = false

    @StateObject private var editorModel = RichTextEditorModel()

    @StateRealmObject var draft: Draft

    @Binding var isLoadingContent: Bool
    @Binding var editorFocus: Bool

    @ObservedObject var attachmentsManager: AttachmentsManager
    @ObservedObject var alert: NewMessageAlert

    let dismiss: DismissAction
    let messageReply: MessageReply?

    private var isRemoteContentBlocked: Bool {
        return UserDefaults.shared.displayExternalContent == .askMe && messageReply?.message.localSafeDisplay == false
    }

    var body: some View {
        VStack {
            AttachmentsHeaderView(attachmentsManager: attachmentsManager)

            RichTextEditor(
                model: editorModel,
                body: $draft.body,
                alert: $alert,
                isShowingCamera: $isShowingCamera,
                isShowingFileSelection: $isShowingFileSelection,
                isShowingPhotoLibrary: $isShowingPhotoLibrary,
                becomeFirstResponder: $editorFocus,
                blockRemoteContent: isRemoteContentBlocked
            )
            .ignoresSafeArea(.all, edges: .bottom)
            .frame(height: editorModel.height + 20)
            .padding(.vertical, 8)
        }
        .task {
            await prepareCompleteDraft()
        }
        .task {
            await prepareReplyForwardBodyAndAttachments()
        }
        .onChange(of: signatureManager.doneLoadingDefaultSignature, perform: { newValue in
            Task {
                await setSignature()
            }
        })
        .fullScreenCover(isPresented: $isShowingCamera) {
            CameraPicker { data in
                attachmentsManager.importAttachments(attachments: [data])
            }
            .ignoresSafeArea()
        }
        .sheet(isPresented: $isShowingFileSelection) {
            DocumentPicker(pickerType: .selectContent([.item]) { urls in
                attachmentsManager.importAttachments(attachments: urls)
            })
            .ignoresSafeArea()
        }
        .sheet(isPresented: $isShowingPhotoLibrary) {
            ImagePicker { results in
                attachmentsManager.importAttachments(attachments: results)
            }
            .ignoresSafeArea()
        }
    }

    private func prepareCompleteDraft() async {
        guard draft.messageUid != nil && draft.remoteUUID.isEmpty else { return }

        do {
            if let fetchedDraft = try await mailboxManager.draft(partialDraft: draft),
               let liveFetchedDraft = fetchedDraft.thaw() {
                draft = liveFetchedDraft
            }
            isLoadingContent = false
        } catch {
            dismiss()
            IKSnackBar.showSnackBar(message: MailError.unknownError.localizedDescription)
        }
    }

    private func prepareReplyForwardBodyAndAttachments() async {
        guard let messageReply else { return }

        let prepareTask = Task.detached {
            try await prepareBody(message: messageReply.message, replyMode: messageReply.replyMode)
            try await prepareAttachments(message: messageReply.message, replyMode: messageReply.replyMode)
        }

        do {
            _ = try await prepareTask.value

            isLoadingContent = false
        } catch {
            dismiss()
            IKSnackBar.showSnackBar(message: MailError.unknownError.localizedDescription)
        }
    }

    private func setSignature() async {
        guard draft.identityId == nil || draft.identityId?.isEmpty == true,
              let defaultSignature = mailboxManager.getStoredSignatures().default else {
            return
        }

        // At this point we have up to date signatures in base
        $draft.identityId.wrappedValue = "\(defaultSignature.id)"

        let html = "<br><br><div class=\"editorUserSignature\">\(defaultSignature.content)</div>"
        switch defaultSignature.position {
        case .beforeReplyMessage:
            $draft.body.wrappedValue.insert(contentsOf: html, at: draft.body.startIndex)
        case .afterReplyMessage:
            $draft.body.wrappedValue.append(contentsOf: html)
        }
    }

    private func prepareBody(message: Message, replyMode: ReplyMode) async throws {
        if !message.fullyDownloaded {
            try await mailboxManager.message(message: message)
        }

        guard let freshMessage = message.thaw() else { return }
        freshMessage.realm?.refresh()
        $draft.body.wrappedValue = Draft.replyingBody(message: freshMessage, replyMode: replyMode)
    }

    private func prepareAttachments(message: Message, replyMode: ReplyMode) async throws {
        guard replyMode == .forward else { return }
        let attachments = try await mailboxManager.apiFetcher.attachmentsToForward(
            mailbox: mailboxManager.mailbox,
            message: message
        ).attachments

        for attachment in attachments {
            $draft.attachments.append(attachment)
        }
        attachmentsManager.completeUploadedAttachments()
    }
}

struct ComposeMessageBodyView_Previews: PreviewProvider {
    static let signaturesManager = SignaturesManager(mailboxManager: PreviewHelper.sampleMailboxManager)

    static var previews: some View {
        @Environment(\.dismiss) var dismiss

        ComposeMessageBodyView(draft: Draft(),
                               isLoadingContent: .constant(false),
                               editorFocus: .constant(false),
                               attachmentsManager: AttachmentsManager(
                                   draft: Draft(),
                                   mailboxManager: PreviewHelper.sampleMailboxManager
                               ),
                               alert: NewMessageAlert(),
                               dismiss: dismiss,
                               messageReply: nil)
            .environmentObject(signaturesManager)
    }
}
