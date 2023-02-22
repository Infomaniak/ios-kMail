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
import SwiftUI

struct FlushFolderView: View {
    private static let labels: [FolderRole: String] = [
        .trash: MailResourcesStrings.Localizable.threadListTrashHint,
        .spam: MailResourcesStrings.Localizable.threadListSpamHint
    ]
    private static let buttons: [FolderRole: String] = [
        .trash: MailResourcesStrings.Localizable.threadListEmptyTrashButton,
        .spam: MailResourcesStrings.Localizable.threadListEmptySpamButton
    ]

    @Binding var flushAlert: FlushAlertState?
    let folder: Folder
    let mailboxManager: MailboxManager

    private var label: String {
        Self.labels[folder.role ?? .trash] ?? ""
    }

    private var button: String {
        Self.buttons[folder.role ?? .trash] ?? ""
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text(label)
                    .textStyle(.bodySmall)

                Button {
                    flushAlert = FlushAlertState {
                        await tryOrDisplayError {
                            _ = try await mailboxManager.flushFolder(folder: folder.freezeIfNeeded())
                        }
                    }
                } label: {
                    HStack {
                        Image(resource: MailResourcesAsset.bin)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                        Text(button)
                    }
                    .textStyle(.bodySmallAccent)
                }
                .buttonStyle(.borderless)
            }
            .padding(16)

            IKDivider()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct FlushFolderView_Previews: PreviewProvider {
    static var previews: some View {
        FlushFolderView(flushAlert: .constant(nil),
                        folder: PreviewHelper.sampleFolder,
                        mailboxManager: PreviewHelper.sampleMailboxManager)
    }
}
