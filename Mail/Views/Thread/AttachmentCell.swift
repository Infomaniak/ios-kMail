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
import SwiftUI

struct AttachmentCell: View {
    let attachment: Attachment
    let uploadTask: AttachmentUploadTask?
    let isNewMessage: Bool
    let attachmentRemoved: ((Attachment) -> Void)?

    init(attachment: Attachment,
         uploadTask: AttachmentUploadTask? = nil,
         isNewMessage: Bool = false,
         attachmentRemoved: ((Attachment) -> Void)?) {
        self.attachment = attachment
        self.uploadTask = uploadTask
        self.isNewMessage = isNewMessage
        self.attachmentRemoved = attachmentRemoved
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(resource: attachment.icon)

                VStack(alignment: .leading, spacing: 0) {
                    Text(attachment.name)
                        .textStyle(.bodySmall)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    if let error = uploadTask?.error {
                        Text(error.localizedDescription)
                            .textStyle(.labelSecondary)
                    } else {
                        Text(attachment.size, format: .defaultByteCount)
                            .textStyle(.labelSecondary)
                            .opacity(attachment.size == 0 ? 0 : 1)
                    }
                }

                if isNewMessage {
                    Button {
                        if let attachmentRemoved = attachmentRemoved {
                            attachmentRemoved(attachment)
                        }
                    } label: {
                        Image(resource: MailResourcesAsset.close)
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(MailResourcesAsset.secondaryTextColor)
                            .frame(width: 16, height: 16)
                    }
                    .buttonStyle(.borderless)
                    .padding(.leading, 8)
                }
            }
            .padding(6)
            if let uploadTask, isNewMessage {
                IndeterminateProgressView(indeterminate: uploadTask.progress == 0, progress: uploadTask.progress)
                    .opacity(uploadTask.progress == 1 ? 0 : 1)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 6)
                .stroke(MailResourcesAsset.separatorColor.swiftUiColor, lineWidth: 1)
        )
        .cornerRadius(6)
        .frame(maxWidth: 200)
        .padding(.top, isNewMessage ? 16 : 0)
    }
}

struct AttachmentCell_Previews: PreviewProvider {
    static var previews: some View {
        AttachmentCell(attachment: PreviewHelper.sampleAttachment) { _ in /* Preview */ }
    }
}
