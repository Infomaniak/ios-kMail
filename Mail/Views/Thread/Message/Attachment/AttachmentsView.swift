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

import DesignSystem
import IKSnackbar
import InfomaniakCore
import InfomaniakCoreCommonUI
import InfomaniakCoreSwiftUI
import InfomaniakDI
import MailCore
import MailCoreUI
import MailResources
import PassKit
import RealmSwift
import SwiftModalPresentation
import SwiftUI

struct AttachmentsView: View {
    @LazyInjectService private var matomo: MatomoUtils

    @EnvironmentObject private var mailboxManager: MailboxManager
    @ObservedRealmObject var message: Message

    @ModalState private var previewedAttachment: UIAttachment?
    @ModalState private var walletPass: WalletPassPresentation?
    @ModalState private var attachmentsURL: AttachmentsURL?
    @State private var downloadProgressState: [UIAttachment.ID: Double] = [:]
    @State private var trackDownloadTask: [UIAttachment.ID: Task<Void, Error>] = [:]
    @State private var downloadAllTask: Task<Void, Never>?
    @State private var downloadAllProgress: Double?
    @State private var isDownloadDisabled = false

    private var attachments: [UIAttachment] {
        message.notInlineAttachments.map {
            UIAttachment(
                attachment: $0,
                messageUid: message.uid,
                localURL: $0.getLocalURL(mailboxManager: mailboxManager)
            )
        }
    }

    private var swissTransferFiles: [UIAttachment] {
        guard let transfer = message.swissTransferAttachment else { return [] }
        return transfer.files.map { UIAttachment(swissTransferFile: $0, transferId: transfer.uuid) }
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
                HStack(spacing: IKPadding.mini) {
                    ForEach(attachments) { attachment in
                        Button {
                            openAttachment(attachment)
                        } label: {
                            AttachmentView(
                                attachment: attachment,
                                downloadProgress: downloadProgressState[attachment.id] ?? 0
                            )
                        }
                        .disabled(isDownloadDisabled)
                    }
                    ForEach(swissTransferFiles) { file in
                        Button {
                            downloadSwissTransferAttachment(file)
                        } label: {
                            AttachmentView(
                                attachment: file,
                                downloadProgress: downloadProgressState[file.id] ?? 0
                            )
                        }
                        .disabled(isDownloadDisabled)
                    }
                }
                .padding(.horizontal, value: .medium)
                .padding(.vertical, 1)
            }

            HStack(alignment: .iconAndMultilineTextAlignment, spacing: IKPadding.mini) {
                MailResourcesAsset.attachment
                    .iconSize(.medium)
                    .foregroundStyle(MailResourcesAsset.textSecondaryColor)

                VStack(alignment: .leading, spacing: IKPadding.micro) {
                    Text("\(formattedText) (\(formattedSize))")
                        .textStyle(.bodySmallSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)

                    DownloadAllAttachmentsButtonView(
                        isDownloadDisabled: isDownloadDisabled,
                        downloadAllAttachments: downloadAllAttachments,
                        progress: downloadAllProgress
                    )
                }
            }
            .padding(.horizontal, value: .medium)
        }
        .task {
            try? await mailboxManager.swissTransferAttachment(message: message)
        }
        .sheet(item: $previewedAttachment) { previewedAttachment in
            AttachmentPreview(attachment: previewedAttachment)
                .pagePresentationSizing()
        }
        .sheet(item: $walletPass) { walletPass in
            AddWalletPassView(controller: walletPass.controller)
        }
        .sheet(item: $attachmentsURL) { attachmentsURL in
            DocumentPicker(pickerType: .exportContent(attachmentsURL.urls))
                .ignoresSafeArea()
        }
        .onDisappear {
            for (_, task) in trackDownloadTask {
                task.cancel()
            }
            downloadAllTask?.cancel()
        }
    }

    private func openAttachment(_ attachment: UIAttachment) {
        guard let url = attachment.localURL else { return }
        matomo.track(eventWithCategory: .attachmentActions, name: "open")
        isDownloadDisabled = true
        if !FileManager.default.fileExists(atPath: url.path) {
            downloadProgressState[attachment.id] = 0
        }
        trackDownloadTask[attachment.id] = Task { @MainActor in
            defer {
                isDownloadDisabled = false
                trackDownloadTask[attachment.id] = nil
            }

            await tryOrDisplayError {
                if !FileManager.default.fileExists(atPath: url.path) {
                    guard let model = message.attachments.first(where: {
                        UIAttachment.id(for: $0, messageUid: message.uid) == attachment.id
                    }) else {
                        throw MailError.resourceError
                    }
                    try await mailboxManager.saveAttachmentLocally(attachment: model.freezeIfNeeded()) { progress in
                        Task { @MainActor in
                            downloadProgressState[attachment.id] = progress
                        }
                    }
                }
                try Task.checkCancellation()
                downloadProgressState[attachment.id] = 1
                openPreviewOrWalletFor(attachment: attachment)
            }
        }
    }

    private func openPreviewOrWalletFor(attachment: UIAttachment) {
        if attachment.isWalletPass && PKAddPassesViewController.canAddPasses(),
           let url = attachment.availableLocalURL,
           let data = try? Data(contentsOf: url, options: [.alwaysMapped]),
           let pass = try? PKPass(data: data),
           let controller = PKAddPassesViewController(pass: pass) {
            walletPass = WalletPassPresentation(controller: controller)

        } else {
            previewedAttachment = attachment
        }
    }

    private func downloadSwissTransferAttachment(_ attachment: UIAttachment) {
        guard case .swissTransfer(let stUuid, let fileUuid) = attachment.id else { return }
        isDownloadDisabled = true
        matomo.track(eventWithCategory: .attachmentActions, name: "openSwissTransfer")

        trackDownloadTask[attachment.id] = Task {
            defer {
                isDownloadDisabled = false
                trackDownloadTask[attachment.id] = nil
            }
            await tryOrDisplayError {
                let attachmentURL = try await mailboxManager.apiFetcher.downloadSwissTransferAttachment(
                    stUuid: stUuid, fileUuid: fileUuid
                ) { progress in
                    Task { @MainActor in
                        downloadProgressState[attachment.id] = progress
                    }
                }
                attachmentsURL = AttachmentsURL(urls: [attachmentURL])
            }
        }
    }

    private func downloadAllAttachments() {
        isDownloadDisabled = true
        downloadAllTask = Task {
            defer {
                isDownloadDisabled = false
                downloadAllTask = nil
            }
            await tryOrDisplayError {
                matomo.track(eventWithCategory: .message, name: "downloadAll")

                try await withThrowingTaskGroup(of: URL.self) { group in
                    var urls = [URL]()
                    group.addTask {
                        try await mailboxManager.apiFetcher.downloadAttachments(message: message, progressObserver: nil)
                    }
                    if let swissTransferAttachment = message.swissTransferAttachment {
                        group.addTask {
                            try await mailboxManager.apiFetcher
                                .downloadAllSwissTransferAttachment(stUuid: swissTransferAttachment.uuid) { progress in
                                    Task { @MainActor in
                                        downloadAllProgress = progress
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
        }
    }
}

struct DownloadAllAttachmentsButtonView: View {
    let isDownloadDisabled: Bool
    let downloadAllAttachments: () -> Void
    let progress: Double?

    var isShowingProgressCircle: Bool {
        guard let progress else { return false }
        return progress > 0 && progress < 1
    }

    var body: some View {
        HStack {
            if isShowingProgressCircle {
                ProgressView(value: progress)
                    .progressViewStyle(.mailCircularProgress)
            }

            Button(action: downloadAllAttachments) {
                Text(MailResourcesStrings.Localizable.buttonDownloadAll)
            }
            .disabled(isDownloadDisabled)
            .buttonStyle(.ikBorderless(isInlined: true))
            .controlSize(.small)
        }
    }
}

#Preview {
    AttachmentsView(message: PreviewHelper.sampleMessage)
        .environmentObject(PreviewHelper.sampleMailboxManager)
}
