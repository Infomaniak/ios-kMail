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

import InfomaniakCoreUI
import InfomaniakDI
import MailCore
import MailCoreUI
import SwiftModalPresentation
import SwiftUI

struct AccountActionsView: View {
    @LazyInjectService private var matomo: MatomoUtils

    @EnvironmentObject private var mailboxManager: MailboxManager

    @ModalState(context: ContextKeys.account) private var isShowingLogoutAlert = false

    private var actions: [Action] {
        return [.addAccount, .logoutAccount]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(actions) { action in
                Button {
                    handleAction(action)
                } label: {
                    ActionButtonLabel(action: action)
                }
            }
        }
        .customAlert(isPresented: $isShowingLogoutAlert) {
            LogoutConfirmationView(account: mailboxManager.account)
        }
    }

    // MARK: - Actions

    private func handleAction(_ action: Action) {
        switch action {
        case .addAccount:
            addAccount()
        case .logoutAccount:
            logoutAccount()
        default:
            return
        }
    }

    private func addAccount() {
        // TODO: handle action
    }

    private func logoutAccount() {
        matomo.track(eventWithCategory: .account, name: "logOut")
        isShowingLogoutAlert.toggle()
    }
}

#Preview {
    AccountActionsView()
}
