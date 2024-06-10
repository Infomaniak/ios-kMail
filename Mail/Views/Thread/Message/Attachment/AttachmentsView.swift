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
    @ModalState private var attachmentsURL: AttachmentsURL?

    @EnvironmentObject var mailboxManager: MailboxManager
    @ObservedRealmObject var message: Message

    @LazyInjectService private var matomo: MatomoUtils

    private var attachments: [Attachment] {
        return message.attachments.filter { $0.disposition == .attachment || $0.contentId == nil }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: UIPadding.regular) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: UIPadding.small) {
                    ForEach(attachments) { attachment in
                        Button {
                            openAttachment(attachment)
                        } label: {
                            AttachmentView(title: attachment.name, subtitle: attachment.size.formatted(.defaultByteCount), icon: attachment.icon)
                        }
                    }
                    if let swissTransferAttachment = message.swissTransferAttachment {
                        ForEach(swissTransferAttachment.files) { file in
                            Button {
                                downloadSwissTransferAttachment(stUuid: swissTransferAttachment.uuid, fileUuid: file.uuid)
                            } label: {
                                AttachmentView(title: file.name, subtitle: file.size.formatted(.defaultByteCount), icon: file.icon)
                            }
                        }
                    }
                }
                .padding(.vertical, 1)
            }

            HStack(alignment: .iconAndMultilineTextAlignment, spacing: UIPadding.small) {
                MailResourcesAsset.attachment.swiftUIImage
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .foregroundStyle(MailResourcesAsset.textSecondaryColor)

                VStack(alignment: .leading, spacing: UIPadding.verySmall) {
                    Text(text())
                        .textStyle(.bodySmallSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)

                    Button(MailResourcesStrings.Localizable.buttonDownloadAll, action: downloadAllAttachments)
                        .buttonStyle(.ikLink(isInlined: true))
                        .controlSize(.small)
                        .ikButtonLoading(downloadInProgress)
                }
            }
        }
        .padding(.horizontal, value: .regular)
        .task {
            try? await mailboxManager.swissTransferAttachment(message: message)
        }
        .sheet(item: $previewedAttachment) { previewedAttachment in
            AttachmentPreview(attachment: previewedAttachment)
                .environmentObject(mailboxManager)
        }
        .sheet(item: $attachmentsURL) { attachmentsURL in
            DocumentPicker(pickerType: .exportContent(attachmentsURL.urls))
                .ignoresSafeArea()
        }
    }

    private func text() -> String {
        if let swissTransferAttachment = message.swissTransferAttachment, !attachments.isEmpty {
            let totalSize = message.attachmentsSize + swissTransferAttachment.size
            return "\(MailResourcesStrings.Localizable.attachmentQuantity(attachments.count)) \(MailResourcesStrings.Localizable.linkingWord) \(MailResourcesStrings.Localizable.fileQuantity(swissTransferAttachment.files.count)) (\(totalSize.formatted(.defaultByteCount)))"
        } else if let swissTransferAttachment = message.swissTransferAttachment, attachments.isEmpty {
            return "\(MailResourcesStrings.Localizable.fileQuantity(swissTransferAttachment.nbfiles)) (\(swissTransferAttachment.size.formatted(.defaultByteCount)))"
        } else {
            return "\(MailResourcesStrings.Localizable.attachmentQuantity(attachments.count)) (\(message.attachmentsSize.formatted(.defaultByteCount)))"
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

    private func downloadSwissTransferAttachment(stUuid: String, fileUuid: String) {
        matomo.track(eventWithCategory: .attachmentActions, name: "openSwissTransfer")

        Task {
            await tryOrDisplayError {
                let attachmentURL = try await mailboxManager.apiFetcher.downloadSwissTransferAttachment(stUuid: stUuid, fileUuid: fileUuid)
                attachmentsURL = AttachmentsURL(urls: [attachmentURL])
            }
        }
    }

    private func downloadAllAttachments() {
        downloadInProgress = true
        Task {
            await tryOrDisplayError {
                matomo.track(eventWithCategory: .message, name: "downloadAll")

                try await withThrowingTaskGroup(of: URL.self) { group in
                    var urls = [URL]()
                    group.addTask {
                        try await mailboxManager.apiFetcher.downloadAttachments(message: message)
                    }
                    if let swissTransferAttachment = message.swissTransferAttachment {
                        group.addTask {
                            try await mailboxManager.apiFetcher.downloadAllSwissTransferAttachment(stUuid: swissTransferAttachment.uuid)
                        }
                    }
                    for try await url in group {
                        urls.append(url)
                    }
                    attachmentsURL = AttachmentsURL(urls: urls)
                }
            }
            downloadInProgress = false
        }
    }
}

#Preview {
    AttachmentsView(message: PreviewHelper.sampleMessage)
}
