/*
 Infomaniak Mail - iOS App
 Copyright (C) 2022 Infomaniak Network SA

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

import InfomaniakCore
import InfomaniakCoreUI
import InfomaniakDI
import MailCore
import MailCoreUI
import MailResources
import RealmSwift
import SwiftModalPresentation
import SwiftUI

struct AttachmentsView: View {
    @ModalState private var previewedAttachment: Attachment?
    @State private var downloadInProgress = false
    @ModalState private var allAttachmentsURL: IdentifiableURL?

    @EnvironmentObject var mailboxManager: MailboxManager
    @ObservedRealmObject var message: Message

    @LazyInjectService private var matomo: MatomoUtils

    private var attachments: [Attachment] {
        return message.attachments.filter { $0.disposition == .attachment || $0.contentId == nil }
    }

    var body: some View {
        VStack(spacing: UIPadding.regular) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: UIPadding.small) {
                    ForEach(attachments) { attachment in
                        Button {
                            openAttachment(attachment)
                        } label: {
                            AttachmentCell(attachment: attachment)
                        }
                    }
                }
                .padding(.horizontal, value: .regular)
                .padding(.vertical, 1)
            }

            HStack(spacing: UIPadding.small) {
                Label {
                    Text(
                        "\(MailResourcesStrings.Localizable.attachmentQuantity(attachments.count)) (\(message.attachmentsSize, format: .defaultByteCount))"
                    )
                } icon: {
                    IKIcon(MailResourcesAsset.attachment)
                        .foregroundStyle(MailResourcesAsset.textSecondaryColor)
                }
                .textStyle(.bodySmallSecondary)

                Button(MailResourcesStrings.Localizable.buttonDownloadAll, action: downloadAllAttachments)
                    .buttonStyle(.ikLink(isInlined: true))
                    .controlSize(.small)
                    .ikButtonLoading(downloadInProgress)

                Spacer()
            }
            .padding(.horizontal, value: .regular)
        }
        .sheet(item: $previewedAttachment) { previewedAttachment in
            AttachmentPreview(attachment: previewedAttachment)
                .environmentObject(mailboxManager)
        }
        .sheet(item: $allAttachmentsURL) { allAttachmentsURL in
            DocumentPicker(pickerType: .exportContent([allAttachmentsURL.url]))
                .ignoresSafeArea()
        }
    }

    private func openAttachment(_ attachment: Attachment) {
        matomo.track(eventWithCategory: .attachmentActions, name: "open")
        previewedAttachment = attachment
        if !FileManager.default.fileExists(atPath: attachment.getLocalURL(mailboxManager: mailboxManager).path) {
            Task {
                await mailboxManager.saveAttachmentLocally(attachment: attachment)
            }
        }
    }

    private func downloadAllAttachments() {
        downloadInProgress = true
        Task {
            await tryOrDisplayError {
                matomo.track(eventWithCategory: .message, name: "downloadAll")
                let attachmentURL = try await mailboxManager.apiFetcher.downloadAttachments(message: message)
                allAttachmentsURL = IdentifiableURL(url: attachmentURL)
            }
            downloadInProgress = false
        }
    }
}

#Preview {
    AttachmentsView(message: PreviewHelper.sampleMessage)
}
