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
import SwiftModalPresentation
import SwiftUI

struct ComposeMessageBodyView: View {
    @State private var isShowingCamera = false
    @ModalState(context: ContextKeys.composeBody) private var isShowingFileSelection = false
    @ModalState(context: ContextKeys.composeBody) private var isShowingPhotoLibrary = false

    @ObservedRealmObject var draft: Draft

    @Binding var editorModel: RichTextEditorModel
    @Binding var editorFocus: Bool
    @Binding var currentSignature: Signature?
    @Binding var isShowingAIPrompt: Bool

    @ObservedObject var attachmentsManager: AttachmentsManager
    @ObservedObject var alert: NewMessageAlert

    let messageReply: MessageReply?

    private var isRemoteContentBlocked: Bool {
        return UserDefaults.shared.displayExternalContent == .askMe && messageReply?.frozenMessage.localSafeDisplay == false
    }

    var body: some View {
        VStack {
            AttachmentsHeaderView(attachmentsManager: attachmentsManager)

            RichTextEditor(
                model: $editorModel,
                body: $draft.body,
                alert: $alert,
                isShowingCamera: $isShowingCamera,
                isShowingFileSelection: $isShowingFileSelection,
                isShowingPhotoLibrary: $isShowingPhotoLibrary,
                becomeFirstResponder: $editorFocus,
                isShowingAIPrompt: $isShowingAIPrompt,
                blockRemoteContent: isRemoteContentBlocked
            )
            .ignoresSafeArea(.all, edges: .bottom)
            .frame(height: editorModel.height + 20)
            .padding(.vertical, value: .verySmall)
        }
        .fullScreenCover(isPresented: $isShowingCamera) {
            CameraPicker { data in
                attachmentsManager.importAttachments(
                    attachments: [data],
                    draft: draft,
                    disposition: AttachmentDisposition.defaultDisposition
                )
            }
            .ignoresSafeArea()
        }
        .sheet(isPresented: $isShowingFileSelection) {
            DocumentPicker(pickerType: .selectContent([.item]) { urls in
                attachmentsManager.importAttachments(
                    attachments: urls,
                    draft: draft,
                    disposition: AttachmentDisposition.defaultDisposition
                )
            })
            .ignoresSafeArea()
        }
        .sheet(isPresented: $isShowingPhotoLibrary) {
            ImagePicker { results in
                attachmentsManager.importAttachments(
                    attachments: results,
                    draft: draft,
                    disposition: AttachmentDisposition.defaultDisposition
                )
            }
            .ignoresSafeArea()
        }
    }
}

#Preview {
    let draft = Draft()
    return ComposeMessageBodyView(draft: draft,
                                  editorModel: .constant(RichTextEditorModel()),
                                  editorFocus: .constant(false),
                                  currentSignature: .constant(nil),
                                  isShowingAIPrompt: .constant(false),
                                  attachmentsManager: AttachmentsManager(
                                      draftLocalUUID: draft.localUUID,
                                      mailboxManager: PreviewHelper.sampleMailboxManager
                                  ),
                                  alert: NewMessageAlert(),
                                  messageReply: nil)
}
