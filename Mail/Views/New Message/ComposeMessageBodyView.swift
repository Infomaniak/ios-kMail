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

import InfomaniakRichHTMLEditor
import MailCore
import MailCoreUI
import OSLog
import PhotosUI
import RealmSwift
import Sentry
import SwiftModalPresentation
import SwiftUI

struct ComposeMessageBodyView: View {
    static let customCSS = MessageWebViewUtils.loadCSS(for: .editor).joined()

    @EnvironmentObject private var attachmentsManager: AttachmentsManager

    @State private var toolbar = EditorMobileToolbarView()
    @StateObject private var textAttributes = TextAttributes()

    @ModalState(context: ContextKeys.compose) private var isShowingLinkAlert = false
    @ModalState(context: ContextKeys.compose) private var isShowingFileSelection = false
    @ModalState(context: ContextKeys.compose) private var isShowingPhotoLibrary = false
    @ModalState(context: ContextKeys.compose) private var isShowingCamera = false

    @FocusState var focusedField: ComposeViewFieldType?

    @ObservedRealmObject var draft: Draft

    @Binding var isShowingAI: Bool

    let messageReply: MessageReply?

    private var isRemoteContentBlocked: Bool {
        return UserDefaults.shared.displayExternalContent == .askMe && messageReply?.frozenMessage.localSafeDisplay == false
    }

    var body: some View {
        VStack {
            #if os(macOS) || targetEnvironment(macCatalyst)
            EditorDesktopToolbarView(
                isShowingLinkAlert: $isShowingLinkAlert,
                isShowingFileSelection: $isShowingFileSelection,
                textAttributes: textAttributes
            )
            #endif
            AttachmentsHeaderView()
            RichHTMLEditor(html: $draft.body, textAttributes: textAttributes)
                .focused($focusedField, equals: .editor)
                .onAppear(perform: setupToolbar)
                .editorInputAccessoryView(toolbar)
                .editorCSS(Self.customCSS)
                .introspectEditor(perform: setupEditor)
                .onJavaScriptFunctionFail(perform: reportJavaScriptError)
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
    }

    private func setupEditor(_ editor: RichHTMLEditorView) {
        Task {
            let contentBlocker = ContentBlocker(webView: editor.webView)
            try? await contentBlocker.setRemoteContentBlocked(isRemoteContentBlocked)
        }
    }

    private func setupToolbar() {
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
            Logger.view.warning("EditorToolbarAction not handled by ComposeEditor.")
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

    private func reportJavaScriptError(_ error: any Error, function: String) {
        SentrySDK.capture(error: error) { scope in
            scope.setExtras([
                "Executed JS Function": function
            ])
        }
    }
}

#Preview {
    let draft = Draft()
    return ComposeMessageBodyView(
        focusedField: .init(),
        draft: draft,
        isShowingAI: .constant(false),
        messageReply: nil
    )
    .environmentObject(AttachmentsManager(
        draftLocalUUID: draft.localUUID,
        mailboxManager: PreviewHelper.sampleMailboxManager
    ))
}
