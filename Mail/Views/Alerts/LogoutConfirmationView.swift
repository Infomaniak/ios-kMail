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
import InfomaniakNotifications
import MailCore
import MailResources
import SwiftUI

struct LogoutConfirmationView: View {
    @LazyInjectService private var accountManager: AccountManager

    let account: Account

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(MailResourcesStrings.Localizable.confirmLogoutTitle)
                .textStyle(.bodyMedium)
                .padding(.bottom, UIPadding.alertTitleBottom)
            Text(MailResourcesStrings.Localizable.confirmLogoutDescription(account.user.email))
                .textStyle(.bodySecondary)
                .padding(.bottom, UIPadding.alertDescriptionBottom)
            ModalButtonsView(primaryButtonTitle: MailResourcesStrings.Localizable.buttonConfirm, primaryButtonAction: logout)
        }
    }

    private func logout() async {
        @InjectService var matomo: MatomoUtils
        matomo.track(eventWithCategory: .account, name: "logOutConfirm")
        @InjectService var notificationService: InfomaniakNotifications
        await notificationService.removeStoredTokenFor(userId: account.userId)

        accountManager.removeTokenAndAccount(account: account)
        if let nextAccount = accountManager.accounts.first {
            accountManager.switchAccount(newAccount: nextAccount)
        }
        accountManager.saveAccounts()
    }
}

struct LogoutConfirmationView_Previews: PreviewProvider {
    static var previews: some View {
        LogoutConfirmationView(account: PreviewHelper.sampleAccount)
    }
}
