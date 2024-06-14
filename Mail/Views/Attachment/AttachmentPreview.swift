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
import Sentry
import SwiftModalPresentation
import SwiftUI

struct AttachmentPreview: View {
    @LazyInjectService private var matomo: MatomoUtils

    @Environment(\.dismiss) private var dismiss
    @Environment(\.verticalSizeClass) private var sizeClass

    @EnvironmentObject private var mailboxManager: MailboxManager

    @ModalState(wrappedValue: nil, context: ContextKeys.attachmentDownload) private var downloadedAttachmentURL: IdentifiableURL?

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
                    CloseButton(dismissAction: dismiss)
                }

                ToolbarItemGroup(placement: .bottomBar) {
                    Button {
                        matomo.track(eventWithCategory: .message, name: "download")
                        downloadedAttachmentURL = IdentifiableURL(url: attachment.getLocalURL(mailboxManager: mailboxManager))
                    } label: {
                        Label {
                            Text(MailResourcesStrings.Localizable.buttonDownload)
                                .font(MailTextStyle.labelSecondary.font)
                        } icon: {
                            IKIcon(MailResourcesAsset.download, size: .large)
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

                    Spacer()

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
                            IKIcon(MailResourcesAsset.kdriveLogo, size: .large)
                        }
                        .dynamicLabelStyle(sizeClass: sizeClass ?? .regular)
                    }
                }
            }
        }
    }
}

#Preview {
    AttachmentPreview(attachment: PreviewHelper.sampleAttachment)
}
