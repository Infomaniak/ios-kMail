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

import InfomaniakCoreCommonUI
import InfomaniakDI
import MailCore
import MailCoreUI
import MailResources
import SwiftModalPresentation
import SwiftUI

struct AttachmentUploadCell: View {
    @EnvironmentObject private var attachmentsManager: AttachmentsManager

    private let attachment: UIAttachment
    private let attachmentRemoved: ((UIAttachment) -> Void)?

    @ObservedObject var uploadTask: AttachmentTask

    @ModalState(wrappedValue: nil, context: ContextKeys.compose) private var previewedAttachment: UIAttachment?

    init(uploadTask: AttachmentTask, attachment: UIAttachment, attachmentRemoved: ((UIAttachment) -> Void)?) {
        self.uploadTask = uploadTask
        self.attachment = attachment
        self.attachmentRemoved = attachmentRemoved
    }

    var body: some View {
        Button {
            previewedAttachment = attachment
        } label: {
            AttachmentView(
                title: attachment.name,
                subtitle: uploadTask.error != nil ? (uploadTask.error!.errorDescription ?? "") : attachment.size
                    .formatted(.defaultByteCount), icon: attachment.icon
            ) {
                Button {
                    if let attachmentRemoved {
                        @InjectService var matomo: MatomoUtils
                        matomo.track(eventWithCategory: .attachmentActions, name: "delete")
                        attachmentRemoved(attachment)
                    }
                } label: {
                    MailResourcesAsset.close
                        .iconSize(.small)
                        .foregroundStyle(MailResourcesAsset.textSecondaryColor)
                }
                .buttonStyle(.borderless)
            }
        }
        .overlay(alignment: .bottom) {
            IndeterminateProgressView(indeterminate: uploadTask.progress == 0, progress: uploadTask.progress)
                .opacity(uploadTask.progress == 1 ? 0 : 1)
        }
        .sheet(item: $previewedAttachment) { attachment in
            AttachmentPreview(attachment: attachment) {
                try await attachmentsManager.saveAttachmentLocally(attachment)
            }
            .pagePresentationSizing()
        }
    }
}

#Preview {
    AttachmentUploadCell(uploadTask: AttachmentTask(), attachment: PreviewHelper.sampleUIAttachment) { _ in
        /* Preview */
    }
    .environmentObject(AttachmentsManager(draftLocalUUID: "", mailboxManager: PreviewHelper.sampleMailboxManager))
}
