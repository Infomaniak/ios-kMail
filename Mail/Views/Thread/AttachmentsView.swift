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

import MailCore
import MailResources
import RealmSwift
import SwiftUI

struct AttachmentsView: View {
    @State private var previewedAttachment: Attachment?
    @EnvironmentObject var mailboxManager: MailboxManager
    @ObservedRealmObject var message: Message

    private var attachments: [Attachment] {
        return message.attachments.filter { $0.contentId == nil }
    }

    var body: some View {
        VStack(spacing: 16) {
            IKDivider()
                .padding(.horizontal, 8)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(attachments) { attachment in
                        Button {
                            previewedAttachment = attachment
                            if !FileManager.default.fileExists(atPath: attachment.localUrl?.path ?? "") {
                                Task {
                                    await mailboxManager.saveAttachmentLocally(attachment: attachment)
                                }
                            }
                        } label: {
                            AttachmentCell(attachment: attachment)
                        }
                    }
                }
                .padding(.vertical, 1)
                .padding(.horizontal, 16)
            }

            HStack(spacing: 8) {
                Label {
                    Text("\(MailResourcesStrings.Localizable.attachmentQuantity(attachments.count)) (\(message.attachmentsSize, format: .defaultByteCount))")
                } icon: {
                    Image(resource: MailResourcesAsset.attachment2)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 15, height: 15)
                }
                .textStyle(.calloutSecondary)

                Button(MailResourcesStrings.Localizable.buttonDownloadAll) {
                    // TODO: Download all attachments
                    showWorkInProgressSnackBar()
                }
                .textStyle(.calloutAccent)

                Spacer()
            }
            .padding(.horizontal, 16)

            IKDivider()
                .padding(.horizontal, 8)
        }
        .sheet(item: $previewedAttachment) { previewedAttachment in
            AttachmentPreview(attachment: previewedAttachment)
        }
    }
}

struct AttachmentsView_Previews: PreviewProvider {
    static var previews: some View {
        AttachmentsView(message: PreviewHelper.sampleMessage)
    }
}
