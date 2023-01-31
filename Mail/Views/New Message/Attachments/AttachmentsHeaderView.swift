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
import MailResources
import RealmSwift
import SwiftUI

struct AttachmentsHeaderView: View {
    @ObservedObject var attachmentsManager: AttachmentsManager

    var body: some View {
        ZStack {
            if !attachmentsManager.attachments.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(attachmentsManager.attachments) { attachment in
                            AttachmentUploadCell(attachment: attachment,
                                                 uploadTask: attachmentsManager.attachmentUploadTaskFor(uuid: attachment.uuid)) { attachmentRemoved in
                                attachmentsManager.removeAttachment(attachmentRemoved)
                            }
                        }
                    }
                    .padding(.vertical, 1)
                }
                .padding(.horizontal, 16)
            }
        }
        .customAlert(item: $attachmentsManager.globalError) { error in
            VStack {
                Text(error.errorDescription ?? MailError.unknownError.errorDescription ?? "")
                BottomSheetButtonsView(primaryButtonTitle: MailResourcesStrings.Localizable.buttonClose) {
                    attachmentsManager.globalError = nil
                    attachmentsManager.objectWillChange.send()
                }
            }
        }
    }
}
