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
    var isNewMessage = false
    let attachmentRemoved: ((Attachment) -> Void)?

    var body: some View {
        HStack {
            Image(resource: attachment.icon)

            VStack(alignment: .leading, spacing: 0) {
                Text(attachment.name)
                    .textStyle(.bodySmall)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Text(attachment.size, format: .defaultByteCount)
                    .textStyle(.captionSecondary)
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
                .buttonStyle(BorderlessButtonStyle())
                .padding(.leading, 8)
            }
        }
        .padding(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(MailResourcesAsset.separatorColor.swiftUiColor, lineWidth: 1)
        )
        .frame(maxWidth: 200)
        .padding(.top, isNewMessage ? 16 : 0)
    }
}

struct AttachmentCell_Previews: PreviewProvider {
    static var previews: some View {
        AttachmentCell(attachment: PreviewHelper.sampleAttachment)  { _ in /* Preview */ }
    }
}
