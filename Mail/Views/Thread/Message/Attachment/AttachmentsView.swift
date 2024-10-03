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
import InfomaniakCoreCommonUI
import InfomaniakCoreSwiftUI
import InfomaniakDI
import MailCore
import MailCoreUI
import MailResources
import RealmSwift
import SwiftModalPresentation
import SwiftUI

struct AttachmentsView: View {
    @LazyInjectService private var matomo: MatomoUtils

    @EnvironmentObject var mailboxManager: MailboxManager
    @ObservedRealmObject var message: Message

    @ModalState private var previewedAttachment: Attachment?
    @ModalState private var attachmentsURL: AttachmentsURL?
    @State private var downloadInProgress = false
    @State private var downloadProgressState: [String: Double] = [:]
    @State private var trackDownloadTask: [String: Task<Void, Error>] = [:]
    @State private var isDownloadDisabled = false
    @State private var isShowingProgressCircle = false

    private var attachments: [Attachment] {
        return message.attachments.filter { $0.disposition == .attachment || $0.contentId == nil }
    }

    private var formattedText: String {
        var text = [String]()
        if !attachments.isEmpty {
            text.append("\(MailResourcesStrings.Localizable.attachmentQuantity(attachments.count))")
        }
        if let swissTransferAttachment = message.swissTransferAttachment {
            text.append("\(MailResourcesStrings.Localizable.fileQuantity(swissTransferAttachment.nbfiles))")
        }
        return text.formatted(.list(type: .and))
    }

    private var formattedSize: String {
        guard let swissTransferAttachment = message.swissTransferAttachment else {
            return message.attachmentsSize.formatted(.defaultByteCount)
        }
        return (Int(message.attachmentsSize) + swissTransferAttachment.size).formatted(.defaultByteCount)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: IKPadding.medium) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: IKPadding.small) {
                    ForEach(attachments) { attachment in
                        let progress = downloadProgressState[attachment.uuid] ?? 0

                        Button {
                            openAttachment(attachment)
                        } label: {
                            AttachmentView(
                                attachment: attachment,
                                isDownloading: progress > 0 && progress < 1,
                                downloadProgress: progress
                            )
                        }
                        .disabled(isDownloadDisabled)
                    }
                    if let swissTransferAttachment = message.swissTransferAttachment {
                        ForEach(swissTransferAttachment.files) { file in
                            let progress = downloadProgressState[file.uuid] ?? 0

                            Button {
                                downloadSwissTransferAttachment(stUuid: swissTransferAttachment.uuid, fileUuid: file.uuid)
                            } label: {
                                AttachmentView(
                                    swissTransferFile: file,
                                    isDownloading: progress > 0 && progress < 1,
                                    downloadProgress: progress
                                )
                            }
                            .disabled(isDownloadDisabled)
                        }
                    }
                }
                .padding(.horizontal, value: .medium)
                .padding(.vertical, 1)
            }

            HStack(alignment: .iconAndMultilineTextAlignment, spacing: IKPadding.small) {
                MailResourcesAsset.attachment
                    .iconSize(.medium)
                    .foregroundStyle(MailResourcesAsset.textSecondaryColor)

                VStack(alignment: .leading, spacing: IKPadding.extraSmall) {
                    Text("\(formattedText) (\(formattedSize))")
                        .textStyle(.bodySmallSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)

                    HStack {
                        let progress = downloadProgressState[message.swissTransferAttachment?.uuid ?? ""] ?? 0
                        if isShowingProgressCircle {
                            ProgressView(value: progress)
                                .progressViewStyle(MailCircularProgressViewStyle())
                        }
                        Button {
                            downloadAllAttachments()
                        } label: {
                            Text(MailResourcesStrings.Localizable.buttonDownloadAll)
                        }
                        .disabled(isDownloadDisabled)
                        .buttonStyle(.ikBorderless(isInlined: true))
                        .controlSize(.small)
                    }
                }
            }
            .padding(.horizontal, value: .medium)
        }
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
        .onDisappear {
            for (_, task) in trackDownloadTask {
                task.cancel()
            }
        }
    }

    private func openAttachment(_ attachment: Attachment) {
        isDownloadDisabled = true
        matomo.track(eventWithCategory: .attachmentActions, name: "open")
        previewedAttachment = attachment
        if !FileManager.default.fileExists(atPath: attachment.getLocalURL(mailboxManager: mailboxManager).path) {
            downloadProgressState[attachment.uuid] = 0.0
            trackDownloadTask[attachment.uuid] = Task { @MainActor in
                await mailboxManager.saveAttachmentLocally(attachment: attachment) { progress in
                    Task { @MainActor in
                        downloadProgressState[attachment.uuid] = progress
                    }
                }
                downloadProgressState[attachment.uuid] = 1.0
            }
        }
        isDownloadDisabled = false
    }

    private func downloadSwissTransferAttachment(stUuid: String, fileUuid: String) {
        isDownloadDisabled = true
        matomo.track(eventWithCategory: .attachmentActions, name: "openSwissTransfer")

        trackDownloadTask[fileUuid] = Task {
            await tryOrDisplayError {
                let attachmentURL = try await mailboxManager.apiFetcher.downloadSwissTransferAttachment(
                    stUuid: stUuid, fileUuid: fileUuid
                ) { progress in
                    Task { @MainActor in
                        downloadProgressState[fileUuid] = progress
                    }
                }
                attachmentsURL = AttachmentsURL(urls: [attachmentURL])
            }
        }
        isDownloadDisabled = false
    }

    private func downloadAllAttachments() {
        downloadInProgress = true
        isDownloadDisabled = true
        isShowingProgressCircle = true
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
                            try await mailboxManager.apiFetcher
                                .downloadAllSwissTransferAttachment(stUuid: swissTransferAttachment.uuid) { progress in
                                    Task { @MainActor in
                                        downloadProgressState[swissTransferAttachment.uuid] = progress
                                    }
                                }
                        }
                    }
                    for try await url in group {
                        urls.append(url)
                    }
                    attachmentsURL = AttachmentsURL(urls: urls)
                }
            }
            downloadInProgress = false
            isDownloadDisabled = false
            isShowingProgressCircle = false
        }
    }
}

#Preview {
    AttachmentsView(message: PreviewHelper.sampleMessage)
}
