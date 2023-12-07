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

struct AttachmentsHeaderView: View {
    @ObservedObject var attachmentsManager: AttachmentsManager

    var body: some View {
        ZStack {
            if !attachmentsManager.liveAttachments.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: UIPadding.small) {
                        ForEach(attachmentsManager.liveAttachments) { attachment in
                            AttachmentUploadCell(
                                uploadTask: attachmentsManager.attachmentUploadTaskOrFinishedTask(for: attachment.uuid),
                                attachment: attachment
                            ) { attachmentRemoved in
                                attachmentsManager.removeAttachment(attachmentRemoved.uuid)
                            }
                        }
                    }
                    .padding(.horizontal, value: .regular)
                }
                .padding(.top, value: .regular)
            }
        }
        .customAlert(item: $attachmentsManager.globalError) { error in
            VStack {
                Text(error.errorDescription ?? MailError.unknownError.errorDescription ?? "")
                ModalButtonsView(primaryButtonTitle: MailResourcesStrings.Localizable.buttonClose, secondaryButtonTitle: nil) {
                    attachmentsManager.objectWillChange.send()
                }
            }
        }
    }
}
