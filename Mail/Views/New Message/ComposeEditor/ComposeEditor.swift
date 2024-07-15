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

import InfomaniakRichEditor
import MailCore
import MailCoreUI
import PhotosUI
import RealmSwift
import SwiftModalPresentation
import SwiftUI

struct ComposeEditor: View {
    static let customCSS = MessageWebViewUtils.loadCSS(for: .editor).joined()

    @State private var toolbar = EditorToolbarView()
    @StateObject private var textAttributes = TextAttributes()

    @ModalState(context: ContextKeys.compose) var isShowingLinkAlert = false
    @ModalState(context: ContextKeys.compose) var isShowingFileSelection = false
    @ModalState(context: ContextKeys.compose) var isShowingPhotoLibrary = false
    @ModalState(context: ContextKeys.compose) var isShowingCamera = false

    @ObservedRealmObject var draft: Draft

    @ObservedObject var attachmentsManager: AttachmentsManager

    @Binding var isShowingAI: Bool

    var body: some View {
        RichEditor(html: $draft.body, textAttributes: textAttributes)
            .editorInputAccessoryView(toolbar)
            .editorCSS(Self.customCSS)
            .onAppear(perform: configureToolbar)
            .customAlert(isPresented: $isShowingLinkAlert) {
                AddLinkView(actionHandler: didCreateLink)
            }
            .sheet(isPresented: $isShowingFileSelection) {
                DocumentPicker(pickerType: .selectContent([.item], didPickDocument))
                    .ignoresSafeArea()
            }
            .sheet(isPresented: $isShowingPhotoLibrary) {
                ImagePicker(completion: didPickImage)
                    .ignoresSafeArea()
            }
            .fullScreenCover(isPresented: $isShowingCamera) {
                CameraPicker(completion: didTakePhoto)
                    .ignoresSafeArea()
            }
    }

    private func configureToolbar() {
        toolbar.setTextAttributes(textAttributes)
        toolbar.mainButtonItemsHandler = didTapMainToolbarButton
    }

    private func didTapMainToolbarButton(_ action: EditorToolbarAction) {
        switch action {
        case .link:
            isShowingLinkAlert = true
        case .ai:
            isShowingAI = true
        case .addFile:
            isShowingFileSelection = true
        case .addPhoto:
            isShowingPhotoLibrary = true
        case .takePhoto:
            isShowingCamera = true
        case .programMessage:
            showWorkInProgressSnackBar()
        default:
            print("Action not handled.")
        }
    }

    private func didCreateLink(url: URL, text: String) {
        textAttributes.addLink(url: url, text: text)
    }

    private func didPickDocument(_ urls: [URL]) {
        attachmentsManager.importAttachments(
            attachments: urls,
            draft: draft,
            disposition: AttachmentDisposition.defaultDisposition
        )
    }

    private func didPickImage(_ results: [PHPickerResult]) {
        attachmentsManager.importAttachments(
            attachments: results,
            draft: draft,
            disposition: AttachmentDisposition.defaultDisposition
        )
    }

    private func didTakePhoto(_ data: Data) {
        attachmentsManager.importAttachments(
            attachments: [data],
            draft: draft,
            disposition: AttachmentDisposition.defaultDisposition
        )
    }
}

#Preview {
    let draft = Draft()
    return ComposeEditor(
        draft: draft,
        attachmentsManager: AttachmentsManager(
            draftLocalUUID: draft.localUUID,
            mailboxManager: PreviewHelper.sampleMailboxManager
        ),
        isShowingAI: .constant(false)
    )
}
