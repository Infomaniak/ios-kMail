/*
 Infomaniak Mail - iOS App
 Copyright (C) 2024 Infomaniak Network SA

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
import InfomaniakCoreCommonUI
import InfomaniakCoreSwiftUI
import InfomaniakDI
import MailCore
import MailCoreUI
import MailResources
import SwiftUI

struct FlushFolderView: View {
    private static let labels: [FolderRole: String] = [
        .spam: MailResourcesStrings.Localizable.threadListSpamHint,
        .trash: MailResourcesStrings.Localizable.threadListTrashHint
    ]
    private static let buttons: [FolderRole: String] = [
        .trash: MailResourcesStrings.Localizable.threadListEmptyTrashButton,
        .spam: MailResourcesStrings.Localizable.threadListEmptySpamButton
    ]

    let folder: Folder
    let mailboxManager: MailboxManager

    @Binding var destructiveAlert: DestructiveActionAlertState?

    private var label: String {
        Self.labels[folder.role ?? .trash] ?? ""
    }

    private var button: String {
        Self.buttons[folder.role ?? .trash] ?? ""
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: IKPadding.mini) {
                Text(label)
                    .textStyle(.bodySmall)

                Button {
                    @InjectService var matomo: MatomoUtils
                    matomo.track(eventWithCategory: .threadList, name: "empty\(folder.matomoName.capitalized)")

                    let frozenFolder = folder.freezeIfNeeded()
                    destructiveAlert = DestructiveActionAlertState(type: .flushFolder(frozenFolder)) {
                        await tryOrDisplayError {
                            _ = try await mailboxManager.flushFolder(folder: frozenFolder)
                        }
                    }
                } label: {
                    HStack(spacing: IKPadding.mini) {
                        MailResourcesAsset.bin
                            .iconSize(.medium)
                        Text(button)
                    }
                    .textStyle(.bodySmallAccent)
                }
                .buttonStyle(.ikBorderless(isInlined: true))
                .controlSize(.small)
            }
            .padding(value: .medium)

            IKDivider(type: .full)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    FlushFolderView(folder: PreviewHelper.sampleFolder,
                    mailboxManager: PreviewHelper.sampleMailboxManager,
                    destructiveAlert: .constant(nil))
}
