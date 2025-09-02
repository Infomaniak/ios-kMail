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
import InfomaniakCore
import InfomaniakCoreCommonUI
import InfomaniakCoreSwiftUI
import InfomaniakDI
import MailCore
import MailCoreUI
import MailResources
import RealmSwift
import Sentry
import SwiftModalPresentation
import SwiftUI

struct AttachmentPreview: View {
    @LazyInjectService private var matomo: MatomoUtils
    @LazyInjectService private var platformDetector: PlatformDetectable

    @Environment(\.dismiss) private var dismiss
    @Environment(\.verticalSizeClass) private var sizeClass

    @EnvironmentObject private var mailboxManager: MailboxManager

    @ModalState(wrappedValue: nil, context: ContextKeys.attachmentDownload) private var downloadedAttachmentURL: IdentifiableURL?
    @ModalState(
        wrappedValue: nil,
        context: ContextKeys.attachmentDownload
    ) private var downloadedAttachmentURLForMac: IdentifiableURL?

    @ObservedRealmObject var attachment: MailCore.Attachment

    var body: some View {
        NavigationView {
            Group {
                if FileManager.default.fileExists(atPath: attachment.getLocalURL(mailboxManager: mailboxManager).path) {
                    PreviewController(url: attachment.getLocalURL(mailboxManager: mailboxManager))
                } else if let temporaryLocalUrl = attachment.temporaryLocalUrl,
                          FileManager.default.fileExists(atPath: temporaryLocalUrl) {
                    PreviewController(url: URL(fileURLWithPath: temporaryLocalUrl))
                } else {
                    ProgressView()
                }
            }
            .navigationBarTitle(attachment.name, displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    ToolbarCloseButton(dismissAction: dismiss)
                }

                ToolbarItemGroup(placement: .bottomBar) {
                    Button {
                        matomo.track(eventWithCategory: .message, name: "share")
                        downloadedAttachmentURL = IdentifiableURL(url: attachment.getLocalURL(mailboxManager: mailboxManager))
                    } label: {
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
                    .sheet(item: $downloadedAttachmentURL) { downloadedAttachmentURL in
                        if #available(iOS 16.0, *) {
                            ActivityView(activityItems: [downloadedAttachmentURL.url])
                                .ignoresSafeArea(edges: [.bottom])
                                .presentationDetents([.medium, .large])
                        } else {
                            ActivityView(activityItems: [downloadedAttachmentURL.url])
                                .ignoresSafeArea(edges: [.bottom])
                                .backport.presentationDetents([.medium, .large])
                        }
                    }

                    if platformDetector.isMac {
                        Button {
                            matomo.track(eventWithCategory: .message, name: "download")
                            downloadedAttachmentURLForMac = IdentifiableURL(url: attachment
                                .getLocalURL(mailboxManager: mailboxManager))
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
                        .sheet(item: $downloadedAttachmentURLForMac) { downloadedAttachmentURLForMac in
                            DocumentPicker(pickerType: .exportContent([downloadedAttachmentURLForMac.url]))
                        }
                    }

                    Spacer()

                    if !platformDetector.isMac {
                        Button {
                            let attachmentURL = attachment.getLocalURL(mailboxManager: mailboxManager)
                            do {
                                try DeeplinkService().shareFileToKdrive(attachmentURL)
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
                    }
                }
            }
        }
    }
}

#Preview {
    AttachmentPreview(attachment: PreviewHelper.sampleAttachment)
        .environmentObject(PreviewHelper.sampleMailboxManager)
}
