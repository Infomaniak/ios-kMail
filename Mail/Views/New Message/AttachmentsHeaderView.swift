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

struct AttachmentsHeaderView: View {
    var attachments: [Attachment]
    @ObservedObject var attachmentsManager: AttachmentsManager

    var body: some View {
        if !attachments.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(attachments) { attachment in
                        AttachmentCell(attachment: attachment,
                                       uploadProgress: attachmentsManager.attachmentsUploadProgress[attachment.uuid ?? ""] ?? 0,
                                       isNewMessage: true) { attachmentRemoved in
                            attachmentsManager.removeAttachment(attachmentRemoved)
                        }
                    }
                }
                .padding(.vertical, 1)
            }
            .padding(.horizontal, 16)
        }
    }
}
