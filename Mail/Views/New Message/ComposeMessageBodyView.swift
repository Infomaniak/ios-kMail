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

import InfomaniakCoreUI
import MailCore
import MailCoreUI
import RealmSwift
import SwiftModalPresentation
import SwiftUI

struct ComposeMessageBodyView: View {
    @State private var isShowingCamera = false
    @ModalState(context: ContextKeys.compose) private var isShowingFileSelection = false
    @ModalState(context: ContextKeys.compose) private var isShowingPhotoLibrary = false

    @ObservedRealmObject var draft: Draft

    @Binding var editorModel: EditorModel
    @Binding var editorFocus: Bool
    @Binding var isShowingAIPrompt: Bool
    @Binding var isShowingAlert: NewMessageAlert?

    @ObservedObject var attachmentsManager: AttachmentsManager

    let messageReply: MessageReply?

    private var isRemoteContentBlocked: Bool {
        return UserDefaults.shared.displayExternalContent == .askMe && messageReply?.frozenMessage.localSafeDisplay == false
    }

    var body: some View {
        VStack {
            AttachmentsHeaderView(attachmentsManager: attachmentsManager)

            EditorView(
                body: $draft.body,
                model: $editorModel,
                isShowingFileSelection: $isShowingFileSelection,
                isShowingCamera: $isShowingCamera,
                isShowingPhotoLibrary: $isShowingPhotoLibrary,
                isShowingAIPrompt: $isShowingAIPrompt,
                isShowingAlert: $isShowingAlert
            )
            .frame(height: editorModel.height)
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
                                  editorModel: .constant(EditorModel()),
                                  editorFocus: .constant(false),
                                  isShowingAIPrompt: .constant(false),
                                  isShowingAlert: .constant(nil),
                                  attachmentsManager: AttachmentsManager(
                                      draftLocalUUID: draft.localUUID,
                                      mailboxManager: PreviewHelper.sampleMailboxManager
                                  ),
                                  messageReply: nil)
}
