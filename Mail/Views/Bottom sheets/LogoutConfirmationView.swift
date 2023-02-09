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

import SwiftUI
import MailResources
import MailCore
import InfomaniakCore

struct LogoutConfirmationView: View {

    @Environment(\.window) private var window

    let account: Account

    let state: AccountAlert

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text( MailResourcesStrings.Localizable.confirmLogoutTitle)
                .textStyle(.bodyMedium)
            Text(MailResourcesStrings.Localizable.confirmLogoutDescription(account.user.email))
                .textStyle(.bodySecondary)
            BottomSheetButtonsView(primaryButtonTitle: MailResourcesStrings.Localizable.buttonConfirm,
                                   secondaryButtonTitle: MailResourcesStrings.Localizable.buttonCancel,
                                   primaryButtonAction: logout,
                                   secondaryButtonAction: cancel)
        }
    }

    private func cancel() {
        state.state = nil
    }

    private func logout() {
        AccountManager.instance.removeTokenAndAccount(token: account.token)
        if let nextAccount = AccountManager.instance.accounts.first {
            (window?.windowScene?.delegate as? SceneDelegate)?.switchAccount(nextAccount)
        } else {
            (window?.windowScene?.delegate as? SceneDelegate)?.showLoginView()
        }
        AccountManager.instance.saveAccounts()
        state.state = nil
    }
}

struct LogoutConfirmationView_Previews: PreviewProvider {
    static var previews: some View {
        LogoutConfirmationView(account: PreviewHelper.sampleAccount, state: AccountAlert())
    }
}
