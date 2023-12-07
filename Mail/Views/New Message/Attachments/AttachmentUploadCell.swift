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

import InfomaniakCoreUI
import InfomaniakDI
import MailCore
import MailResources
import SwiftUI

struct AttachmentUploadCell: View {
    private let detachedAttachment: Attachment
    private let attachmentRemoved: ((Attachment) -> Void)?

    @ObservedObject var uploadTask: AttachmentUploadTask

    init(uploadTask: AttachmentUploadTask, attachment: Attachment, attachmentRemoved: ((Attachment) -> Void)?) {
        self.uploadTask = uploadTask
        detachedAttachment = attachment.detached()
        self.attachmentRemoved = attachmentRemoved
    }

    var body: some View {
        AttachmentView(
            attachment: detachedAttachment,
            subtitle: uploadTask.error != nil ? uploadTask.error!.localizedDescription : detachedAttachment.size
                .formatted(.defaultByteCount)
        ) {
            Button {
                if let attachmentRemoved {
                    @InjectService var matomo: MatomoUtils
                    matomo.track(eventWithCategory: .attachmentActions, name: "delete")
                    attachmentRemoved(detachedAttachment)
                }
            } label: {
                IKIcon(MailResourcesAsset.close, size: .small)
                    .foregroundStyle(MailResourcesAsset.textSecondaryColor)
            }
            .buttonStyle(.borderless)
        }
        .overlay(alignment: .bottom) {
            IndeterminateProgressView(indeterminate: uploadTask.progress == 0, progress: uploadTask.progress)
                .opacity(uploadTask.progress == 1 ? 0 : 1)
        }
    }
}

struct AttachmentUploadCell_Previews: PreviewProvider {
    static var previews: some View {
        AttachmentUploadCell(uploadTask: AttachmentUploadTask(), attachment: PreviewHelper.sampleAttachment) { _ in
            /* Preview */
        }
    }
}
