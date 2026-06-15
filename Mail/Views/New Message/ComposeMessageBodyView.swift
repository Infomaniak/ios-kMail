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
@_spi(Advanced) import SwiftUIIntrospect

struct ComposeMessageBodyView: View {
    @EnvironmentObject private var attachmentsManager: AttachmentsManager

    @ModalState(context: ContextKeys.compose) private var isShowingLinkAlert = false
    @ModalState(wrappedValue: nil, context: ContextKeys.compose) private var isShowingLink: SelectionLink?
    @ModalState(context: ContextKeys.compose) private var isShowingFileSelection = false

    @ObservedObject var textAttributes: TextAttributes

    @FocusState var focusedField: ComposeViewFieldType?

    @State private var mentionDeletionHandler: MentionDeletionHandler?

    @Binding var draftBody: String
    @Binding var isShowingAI: Bool
    @Binding var selectedText: String
    @Binding var mentionQuery: String
    let draft: Draft
    let aliases: [String]

    @State private var inlineAttachmentHandler: InlineAttachmentHandler?

    @Weak var editor: RichHTMLEditorView?

    let messageReply: MessageReply?

    private var isEnvironmentCatalyst: Bool {
        #if targetEnvironment(macCatalyst)
        return true
        #else
        return false
        #endif
    }

    private var isRemoteContentBlocked: Bool {
        return UserDefaults.shared.displayExternalContent == .askMe && messageReply?.frozenMessage.localSafeDisplay == false
    }

    private var customCSS: String {
        return MessageWebViewUtils.loadCSS(for: .editor(aliases: aliases)).joined()
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
            .onJavaScriptFunctionFail(perform: reportJavaScriptError)
            .mailCustomAlert(isPresented: $isShowingLinkAlert) {
                AddLinkView(selectionLink: .empty, actionHandler: didCreateLink)
            }
            #endif
            AttachmentsHeaderView()
            RichHTMLEditor(html: $draftBody, selection: $selectedText, textAttributes: textAttributes,
                           spellCheckEnabled: !isEnvironmentCatalyst,
                           autoCorrectEnabled: !isEnvironmentCatalyst)
                .focused($focusedField, equals: .editor)
                .onEditorLoaded(perform: editorDidLoad)
                .editorCSS(customCSS)
                .introspectEditor(perform: setupEditor)
                .onJavaScriptFunctionFail(perform: reportJavaScriptError)
                .mailCustomAlert(item: $isShowingLink) { link in
                    AddLinkView(selectionLink: link, actionHandler: didCreateLink)
                }
                .onMentionQueryChange { query in
                    mentionQuery = query
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

            if mentionDeletionHandler == nil {
                let handler = MentionDeletionHandler(draft: draft)
                editor.webView.configuration.userContentController.add(handler, name: MentionDeletionHandler.messageName)
                mentionDeletionHandler = handler
            }
            editor.webView.loadUserScript(.observeMentionDeletion)
            if inlineAttachmentHandler == nil {
                let handler = InlineAttachmentHandler(attachmentsManager: attachmentsManager)
                editor.webView.configuration.userContentController.add(handler, name: InlineAttachmentHandler.messageName)
                inlineAttachmentHandler = handler
            }

            editor.webView.loadUserScript(.observeInlineAttachmentsDeletion)

            Task { @MainActor in
                self.editor = editor
            }
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
    ComposeMessageBodyView(
        textAttributes: TextAttributes(),
        focusedField: .init(),
        draftBody: .constant(""),
        isShowingAI: .constant(false),
        selectedText: .constant(""),
        mentionQuery: .constant(""),
        draft: draft,
        aliases: [],
        editor: .init(wrappedValue: nil),
        messageReply: nil
    )
    .environmentObject(AttachmentsManager(
        draftLocalUUID: draft.localUUID,
        mailboxManager: PreviewHelper.sampleMailboxManager
    ))
}
