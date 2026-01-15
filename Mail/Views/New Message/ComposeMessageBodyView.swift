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

import InfomaniakCoreSwiftUI
import InfomaniakRichHTMLEditor
import MailCore
import MailCoreUI
import MailResources
import OSLog
import PhotosUI
import RealmSwift
import Sentry
import SwiftModalPresentation
import SwiftUI

struct ComposeMessageBodyView: View {
    static let customCSS = MessageWebViewUtils.loadCSS(for: .editor).joined()

    @EnvironmentObject private var attachmentsManager: AttachmentsManager

    @ModalState(context: ContextKeys.compose) private var isShowingLinkAlert = false
    @ModalState(context: ContextKeys.compose) private var isShowingFileSelection = false

    @ObservedObject var textAttributes: TextAttributes

    @FocusState var focusedField: ComposeViewFieldType?
    @Binding var draftBody: String
    let draft: Draft
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
                isShowingAI: $isShowingAI,
                textAttributes: textAttributes
            )
            #endif
            AttachmentsHeaderView()
            RichHTMLEditor(html: $draftBody, textAttributes: textAttributes)
                .focused($focusedField, equals: .editor)
                .onEditorLoaded(perform: editorDidLoad)
                .editorCSS(Self.customCSS)
                .introspectEditor(perform: setupEditor)
                .onJavaScriptFunctionFail(perform: reportJavaScriptError)
                .mailCustomAlert(isPresented: $isShowingLinkAlert) {
                    AddLinkView(actionHandler: didCreateLink)
                }
                .sheet(isPresented: $isShowingFileSelection) {
                    DocumentPicker(pickerType: .selectContent([.item], didPickDocument))
                        .ignoresSafeArea()
                }
        }
    }

    private func editorDidLoad(_ richHTMLEditorView: RichHTMLEditorView) {
        Task {
            try? await richHTMLEditorView.webView.evaluateJavaScript(.removeAllProperties)
        }
    }

    private func setupEditor(_ editor: RichHTMLEditorView) {
        Task {
            let contentBlocker = ContentBlocker(webView: editor.webView)
            try? await contentBlocker.setRemoteContentBlocked(isRemoteContentBlocked)

            disableDragAndDrop(editor: editor)

            editor.webView.loadUserScript(.fixEmailStyle)
        }
    }

    private func disableDragAndDrop(editor: RichHTMLEditorView) {
        guard let wkScrollView = editor.webView.subviews.compactMap({ $0 as? UIScrollView }).first else {
            return
        }

        guard let contentView = wkScrollView.subviews.first(where: { !$0.interactions.isEmpty }) else {
            return
        }

        guard let dropInteraction = contentView.interactions.compactMap({ $0 as? UIDropInteraction }).first else {
            return
        }

        contentView.pasteConfiguration = nil
        contentView.removeInteraction(dropInteraction)
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
        textAttributes: TextAttributes(),
        focusedField: .init(),
        draftBody: .constant(""),
        draft: draft,
        isShowingAI: .constant(false),
        messageReply: nil
    )
    .environmentObject(AttachmentsManager(
        draftLocalUUID: draft.localUUID,
        mailboxManager: PreviewHelper.sampleMailboxManager
    ))
}
