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
import InfomaniakRichEditor
import MailCore
import MailCoreUI
import RealmSwift
import SwiftUI

struct ComposeMessageBodyView: View {
    @State private var textAttributes = TextAttributes()
    @StateObject private var toolbarModel = EditorToolbarModel()

    @ObservedRealmObject var draft: Draft

    @Binding var editorFocus: Bool
    @Binding var currentSignature: Signature?

    @ObservedObject var attachmentsManager: AttachmentsManager

    let messageReply: MessageReply?

    private var isRemoteContentBlocked: Bool {
        return UserDefaults.shared.displayExternalContent == .askMe && messageReply?.frozenMessage.localSafeDisplay == false
    }

    private var customCSS: String {
        return MessageWebViewUtils.loadCSS(for: .editor).joined()
    }

    var body: some View {
        VStack {
            AttachmentsHeaderView(attachmentsManager: attachmentsManager)

            RichEditor(html: $draft.body, textAttributes: $textAttributes)
                .editorScrollable(true)
                .editorInputAccessoryView(UIView())
                .editorCSS(customCSS)
                .introspectEditor { richEditorView in
                    // TODO: Customize editor here.
                }
        }
        .customAlert(item: $toolbarModel.isShowingAlert) { alert in
            switch alert.type {
            case .link(let handler):
                AddLinkView(actionHandler: handler)
            }
        }
        .fullScreenCover(isPresented: $toolbarModel.isShowingCamera) {
            CameraPicker { data in
                attachmentsManager.importAttachments(
                    attachments: [data],
                    draft: draft,
                    disposition: AttachmentDisposition.defaultDisposition
                )
            }
            .ignoresSafeArea()
        }
        .sheet(isPresented: $toolbarModel.isShowingFileSelection) {
            DocumentPicker(pickerType: .selectContent([.item]) { urls in
                attachmentsManager.importAttachments(
                    attachments: urls,
                    draft: draft,
                    disposition: AttachmentDisposition.defaultDisposition
                )
            })
            .ignoresSafeArea()
        }
        .sheet(isPresented: $toolbarModel.isShowingPhotoLibrary) {
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
                                  editorFocus: .constant(false),
                                  currentSignature: .constant(nil),
                                  attachmentsManager: AttachmentsManager(
                                      draftLocalUUID: draft.localUUID,
                                      mailboxManager: PreviewHelper.sampleMailboxManager
                                  ),
                                  messageReply: nil)
}
