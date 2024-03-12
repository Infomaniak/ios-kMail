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
import InfomaniakLogin
import MailCore
import MailResources
import RealmSwift
import SwiftUI

struct AccountCellView: View {
    @LazyInjectService private var matomo: MatomoUtils
    @LazyInjectService private var accountManager: AccountManager

    @Environment(\.dismissModal) private var dismissModal

    @Binding var selectedUserId: Int?

    let mailboxManager: MailboxManager?
    let account: Account

    private var isSelected: Bool {
        return selectedUserId == account.userId
    }

    var body: some View {
        Button {
            guard !isSelected else { return }

            matomo.track(eventWithCategory: .account, name: "switch")
            dismissModal()
            accountManager.switchAccount(newAccount: account)
        } label: {
            AccountHeaderCell(account: account, mailboxManager: mailboxManager, isSelected: Binding(get: {
                isSelected
            }, set: {
                selectedUserId = $0 ? account.userId : nil
            }))
        }
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(MailResourcesAsset.backgroundSecondaryColor.swiftUIColor)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(MailResourcesAsset.elementsColor.swiftUIColor, lineWidth: 1)
        }
    }
}

struct AccountHeaderCell: View {
    let account: Account

    /// Optional as this view can be displayed from a context without a mailboxManager available
    let mailboxManager: MailboxManager?

    @Binding var isSelected: Bool

    enum AccountHeaderCellType {
        case switchAccount, selectComposeMailbox
    }

    var type = AccountHeaderCellType.switchAccount

    var body: some View {
        HStack(spacing: UIPadding.small) {
            AvatarView(mailboxManager: mailboxManager, contactConfiguration: .user(user: account.user), size: 40)
            VStack(alignment: .leading, spacing: 0) {
                Text(account.user.displayName)
                    .textStyle(.bodyMedium)
                Text(account.user.email)
                    .textStyle(.bodySecondary)
            }
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .leading)

            switch type {
            case .switchAccount:
                if isSelected {
                    IKIcon(MailResourcesAsset.check)
                        .foregroundStyle(.tint)
                }
            case .selectComposeMailbox:
                ChevronIcon(direction: .down)
            }
        }
        .padding(.vertical, value: .small)
        .padding(.horizontal, value: .regular)
    }
}

#Preview {
    AccountCellView(
        selectedUserId: .constant(nil),
        mailboxManager: nil,
        account: Account(apiToken: ApiToken(
            accessToken: "",
            expiresIn: .max,
            refreshToken: "",
            scope: "",
            tokenType: "",
            userId: 0,
            expirationDate: .distantFuture
        ))
    )
}
