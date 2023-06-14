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

import MailCore
import RealmSwift
import SwiftUI

struct ComposeMessageBodyViewV2: View {
    @State private var isShowingCamera = false
    @State private var isShowingFileSelection = false
    @State private var isShowingPhotoLibrary = false

    @StateObject private var editorModel = RichTextEditorModel()

    @ObservedObject var attachmentsManager: AttachmentsManager
    @ObservedObject var alert: NewMessageAlert
    @ObservedRealmObject var draft: Draft

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
                becomeFirstResponder: .constant(false), // TODO: Give real value
                blockRemoteContent: false // TODO: Give real value
            )
        }
    }
}

struct ComposeMessageBodyViewV2_Previews: PreviewProvider {
    static var previews: some View {
        ComposeMessageBodyViewV2(
            attachmentsManager: AttachmentsManager(draft: Draft(), mailboxManager: PreviewHelper.sampleMailboxManager),
            alert: NewMessageAlert(),
            draft: Draft()
        )
    }
}
