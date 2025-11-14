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
import OSLog
import PhotosUI
import RealmSwift
import Sentry
import SwiftModalPresentation
import SwiftUI

final class DropHandler: DropDelegate {
    static let handledUTTypes: [UTType] = [.image]

    private let attachmentManager: AttachmentsManager
    private let draft: Draft

    init(draft: Draft, attachmentManager: AttachmentsManager) {
        self.draft = draft
        self.attachmentManager = attachmentManager
    }

    func performDrop(info: DropInfo) -> Bool {
        guard info.hasItemsConforming(to: DropHandler.handledUTTypes) else {
            return false
        }

        let itemProviders = info.itemProviders(for: DropHandler.handledUTTypes)
        attachmentManager.importAttachments(attachments: itemProviders, draft: draft, disposition: .attachment)

        return true
    }
}

struct ComposeMessageBodyView: View {
    static let customCSS = MessageWebViewUtils.loadCSS(for: .editor).joined()

    @ModalState(context: ContextKeys.compose) private var isShowingLinkAlert = false
    @ModalState(context: ContextKeys.compose) private var isShowingFileSelection = false

    @State private var dropHandler: DropHandler

    @ObservedObject var attachmentsManager: AttachmentsManager
    @ObservedObject var textAttributes: TextAttributes

    @FocusState var focusedField: ComposeViewFieldType?
    @Binding var draftBody: String
    let draft: Draft
    @Binding var isShowingAI: Bool

    let messageReply: MessageReply?

    private var isRemoteContentBlocked: Bool {
        return UserDefaults.shared.displayExternalContent == .askMe && messageReply?.frozenMessage.localSafeDisplay == false
    }

    init(
        attachmentsManager: AttachmentsManager,
        textAttributes: TextAttributes,
        focusedField: FocusState<ComposeViewFieldType?>,
        draftBody: Binding<String>,
        draft: Draft,
        isShowingAI: Binding<Bool>,
        messageReply: MessageReply?
    ) {
        _attachmentsManager = ObservedObject(wrappedValue: attachmentsManager)
        _textAttributes = ObservedObject(wrappedValue: textAttributes)
        _focusedField = focusedField
        _draftBody = draftBody
        self.draft = draft
        _isShowingAI = isShowingAI
        self.messageReply = messageReply

        _dropHandler = State(wrappedValue: DropHandler(draft: draft, attachmentManager: attachmentsManager))
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
        .onDrop(of: DropHandler.handledUTTypes, delegate: dropHandler)
    }

    private func setupEditor(_ editor: RichHTMLEditorView) {
        Task {
            let contentBlocker = ContentBlocker(webView: editor.webView)
            try? await contentBlocker.setRemoteContentBlocked(isRemoteContentBlocked)
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
        attachmentsManager: AttachmentsManager(
            draftLocalUUID: draft.localUUID,
            mailboxManager: PreviewHelper.sampleMailboxManager
        ),
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
