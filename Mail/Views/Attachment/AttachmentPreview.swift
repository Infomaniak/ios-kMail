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

import InfomaniakCore
import InfomaniakCoreUI
import InfomaniakDI
import MailCore
import MailResources
import RealmSwift
import SwiftUI

struct AttachmentPreview: View {
    @LazyInjectService private var matomo: MatomoUtils

    @Environment(\.dismiss) private var dismiss
    @Environment(\.verticalSizeClass) private var sizeClass

    @State private var downloadedAttachmentURL: IdentifiableURL?

    @ObservedRealmObject var attachment: Attachment

    var body: some View {
        NavigationView {
            Group {
                if FileManager.default.fileExists(atPath: attachment.localUrl.path) {
                    PreviewController(url: attachment.localUrl)
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
                        downloadedAttachmentURL = IdentifiableURL(url: attachment.localUrl)
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
                }
            }
        }
    }
}

#Preview {
    AttachmentPreview(attachment: PreviewHelper.sampleAttachment)
}
