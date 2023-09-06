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
    @State private var isShowingCamera = false
    @State private var isShowingFileSelection = false
    @State private var isShowingPhotoLibrary = false

    @ObservedRealmObject var draft: Draft

    @Binding var editorModel: RichTextEditorModel
    @Binding var editorFocus: Bool
    @Binding var currentSignature: Signature?

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
                model: $editorModel,
                body: $draft.body,
                alert: $alert,
                isShowingCamera: $isShowingCamera,
                isShowingFileSelection: $isShowingFileSelection,
                isShowingPhotoLibrary: $isShowingPhotoLibrary,
                becomeFirstResponder: $editorFocus,
                currentSignature: $currentSignature,
                blockRemoteContent: isRemoteContentBlocked
            )
            .ignoresSafeArea(.all, edges: .bottom)
            .frame(height: editorModel.height + 20)
            .padding(.vertical, value: .verySmall)
        }
        .fullScreenCover(isPresented: $isShowingCamera) {
            CameraPicker { data in
                attachmentsManager.importAttachments(attachments: [data], draft: draft)
            }
            .ignoresSafeArea()
        }
        .sheet(isPresented: $isShowingFileSelection) {
            DocumentPicker(pickerType: .selectContent([.item]) { urls in
                attachmentsManager.importAttachments(attachments: urls, draft: draft)
            })
            .ignoresSafeArea()
        }
        .sheet(isPresented: $isShowingPhotoLibrary) {
            ImagePicker { results in
                attachmentsManager.importAttachments(attachments: results, draft: draft)
            }
            .ignoresSafeArea()
        }
    }
}

struct ComposeMessageBodyView_Previews: PreviewProvider {
    static var previews: some View {
        @Environment(\.dismiss) var dismiss

        ComposeMessageBodyView(draft: Draft(),
                               editorModel: .constant(RichTextEditorModel()),
                               editorFocus: .constant(false),
                               currentSignature: .constant(nil),
                               attachmentsManager: AttachmentsManager(
                                   draft: Draft(),
                                   mailboxManager: PreviewHelper.sampleMailboxManager
                               ),
                               alert: NewMessageAlert(),
                               dismiss: dismiss,
                               messageReply: nil)
    }
}
