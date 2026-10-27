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
import InfomaniakCoreUIKit
import InfomaniakDI
import MailCore
import MailCoreUI
import MailResources
import Sentry
import SwiftModalPresentation
import SwiftUI

struct AttachmentPreview: View {
    @LazyInjectService private var matomo: MatomoUtils
    @InjectService private var platformDetector: PlatformDetectable

    @Environment(\.dismiss) private var dismiss
    @Environment(\.verticalSizeClass) private var sizeClass

    @ModalState(
        wrappedValue: nil,
        context: ContextKeys.attachmentDownload
    ) private var downloadedAttachmentURLForMac: IdentifiableURL?

    @State private var previewURL: URL?

    let attachment: UIAttachment
    var download: (() async throws -> URL)?

    var body: some View {
        NavigationStack {
            Group {
                if let previewURL {
                    PreviewController(
                        url: previewURL,
                        mimeType: attachment.mimeType
                    )
                } else {
                    ProgressView()
                }
            }
            .navigationTitle(attachment.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    ToolbarCloseButton(dismissAction: dismiss)
                }

                ToolbarItemGroup(placement: .bottomBar) {
                    ShareLink(item: previewURL ?? URL(fileURLWithPath: "")) {
                        Label {
                            Text(MailResourcesStrings.Localizable.buttonShare)
                                .font(MailTextStyle.labelSecondary.font)
                        } icon: {
                            Image(systemName: "square.and.arrow.up")
                                .resizable()
                                .scaledToFit()
                                .frame(width: IKIconSize.large.rawValue, height: IKIconSize.large.rawValue)
                        }
                        .dynamicLabelStyle(sizeClass: sizeClass ?? .regular)
                    }
                    .disabled(previewURL == nil)

                    if platformDetector.isMac {
                        Button {
                            guard let previewURL else { return }
                            matomo.track(eventWithCategory: .message, name: "download")
                            downloadedAttachmentURLForMac = IdentifiableURL(url: previewURL)
                        } label: {
                            Label {
                                Text(MailResourcesStrings.Localizable.buttonDownload)
                                    .font(MailTextStyle.labelSecondary.font)
                            } icon: {
                                Image(systemName: "square.and.arrow.down")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: IKIconSize.large.rawValue, height: IKIconSize.large.rawValue)
                            }
                            .dynamicLabelStyle(sizeClass: sizeClass ?? .regular)
                        }
                        .disabled(previewURL == nil)
                        .sheet(item: $downloadedAttachmentURLForMac) { downloadedAttachmentURLForMac in
                            DocumentPicker(pickerType: .exportContent([downloadedAttachmentURLForMac.url]))
                        }
                    }

                    Spacer()

                    if !platformDetector.isMac {
                        Button {
                            guard let previewURL else { return }
                            do {
                                try DeeplinkService().shareFilesToKdrive([previewURL])
                            } catch {
                                SentrySDK.capture(error: error)
                            }
                        } label: {
                            Label {
                                Text(MailResourcesStrings.Localizable.buttonOpenKdrive)
                                    .font(MailTextStyle.labelSecondary.font)
                            } icon: {
                                MailResourcesAsset.kdriveLogo
                                    .iconSize(.large)
                            }
                            .dynamicLabelStyle(sizeClass: sizeClass ?? .regular)
                        }
                        .disabled(previewURL == nil)
                    }
                }
            }
        }
        .task(id: attachment, downloadAttachmentIfNeeded)
    }

    private func downloadAttachmentIfNeeded() async {
        if let localPreviewURL = attachment.availableLocalURL {
            previewURL = localPreviewURL
            return
        }

        do {
            let downloadedURL = try await download?()
            try Task.checkCancellation()
            previewURL = downloadedURL ?? attachment.availableLocalURL
        } catch is CancellationError {
            return
        } catch {
            @InjectService var snackbarPresenter: IKSnackBarPresentable
            snackbarPresenter.show(message: MailResourcesStrings.Localizable.errorUnknown)
            dismiss()
        }
    }
}

public extension View {
    func pagePresentationSizing() -> some View {
        if #available(iOS 18.0, *) {
            return presentationSizing(.page)
        } else {
            return self
        }
    }
}

#Preview {
    AttachmentPreview(attachment: PreviewHelper.sampleUIAttachment)
        .pagePresentationSizing()
}
