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
    @EnvironmentObject private var mailboxManager: MailboxManager

    private let attachment: Attachment
    private let attachmentRemoved: ((Attachment) -> Void)?

    @ObservedObject var uploadTask: AttachmentTask

    @ModalState(wrappedValue: nil, context: ContextKeys.compose) private var previewedAttachment: Attachment?

    init(uploadTask: AttachmentTask, attachment: Attachment, attachmentRemoved: ((Attachment) -> Void)?) {
        self.uploadTask = uploadTask
        self.attachment = attachment
        self.attachmentRemoved = attachmentRemoved
    }

    var body: some View {
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
        .overlay(alignment: .bottom) {
            IndeterminateProgressView(indeterminate: uploadTask.progress == 0, progress: uploadTask.progress)
                .opacity(uploadTask.progress == 1 ? 0 : 1)
        }
        .onTapGesture {
            showAttachmentPreview()
        }
        .sheet(item: $previewedAttachment) { previewedAttachment in
            AttachmentPreview(attachment: previewedAttachment)
                .environmentObject(mailboxManager)
                .pagePresentationSizing()
        }
    }

    private func showAttachmentPreview() {
        guard let attachment = attachment.thaw()?.freezeIfNeeded() else { return }
        previewedAttachment = attachment
        if !FileManager.default.fileExists(atPath: attachment.getLocalURL(mailboxManager: mailboxManager).path) {
            Task {
                await mailboxManager.saveAttachmentLocally(attachment: attachment, progressObserver: nil)
            }
        }
    }
}

#Preview {
    AttachmentUploadCell(uploadTask: AttachmentTask(), attachment: PreviewHelper.sampleAttachment) { _ in
        /* Preview */
    }
}
