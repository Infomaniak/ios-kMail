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
import InfomaniakCore
import InfomaniakCoreSwiftUI
import MailCore
import MailCoreUI
import MailResources
import SwiftUI

struct MailboxesManagementButtonView: View {
    @Environment(\.mailboxCellStyle) private var style: MailboxCell.Style

    let icon: Image
    let mailbox: Mailbox
    let handleAction: (() -> Void)?
    let isSelected: Bool

    private var detailNumber: Int? {
        return mailbox.unseenMessages > 0 ? mailbox.unseenMessages : nil
    }

    init(
        icon: MailResourcesImages,
        mailbox: Mailbox,
        isSelected: Bool,
        handleAction: (() -> Void)? = nil
    ) {
        self.icon = icon.swiftUIImage
        self.mailbox = mailbox
        self.isSelected = isSelected
        self.handleAction = handleAction
    }

    var body: some View {
        Button {
            handleAction?()
        } label: {
            HStack(spacing: IKPadding.medium) {
                icon
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(.tint)
                Text(mailbox.emailIdn)
                    .textStyle(.body)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if mailbox.isLocked && style != .locked {
                    MailResourcesAsset.warningFill.swiftUIImage
                        .foregroundStyle(MailResourcesAsset.orangeColor.swiftUIColor)
                } else {
                    switch style {
                    case .menuDrawer:
                        if let detailNumber {
                            Text(detailNumber, format: .indicatorCappedCount)
                                .textStyle(.bodySmallMediumAccent)
                        } else if mailbox.remoteUnseenMessages != 0 {
                            UnreadIndicatorView()
                        }
                    case .account:
                        if isSelected {
                            MailResourcesAsset.check.swiftUIImage
                                .frame(width: 16, height: 16)
                                .foregroundStyle(.tint)
                        }
                    case .locked:
                        EmptyView()
                    }
                }
            }
        }
    }
}

#Preview {
    MailboxesManagementButtonView(
        icon: MailResourcesAsset.folder,
        mailbox: PreviewHelper.sampleMailbox,
        isSelected: false
    )
}

#Preview {
    MailboxesManagementButtonView(
        icon: MailResourcesAsset.folder,
        mailbox: PreviewHelper.sampleMailbox,
        isSelected: true
    )
}
