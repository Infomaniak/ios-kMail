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
import NavigationBackport
import SwiftUI

struct SelectComposeMailboxView: View {
    @LazyInjectService private var accountManager: AccountManager
    @LazyInjectService private var matomo: MatomoUtils
    @LazyInjectService private var platformDetector: PlatformDetectable

    @AppStorage(UserDefaults.shared.key(.accentColor)) private var accentColor = DefaultPreferences.accentColor

    @Binding var composeMessageIntent: ComposeMessageIntent

    let viewModel: SelectComposeMailboxViewModel

    var body: some View {
        VStack(spacing: 0) {
            accentColor.mailboxImage.swiftUIImage
                .padding(.bottom, value: .regular)

            Text(MailResourcesStrings.Localizable.composeMailboxSelectionTitle)
                .textStyle(.header2)
                .multilineTextAlignment(.center)
                .padding(.bottom, value: .medium)

            ScrollView {
                ForEach(viewModel.accounts) { account in
                    AccountMailboxesListView(
                        account: account,
                        selectedMailbox: viewModel.selectedMailbox,
                        selectMailbox: viewModel.selectMailbox
                    )
                }
            }

            if let selectedMailbox = viewModel.selectedMailbox,
               let account = accountManager.account(for: selectedMailbox.userId), viewModel.selectionMade {
                SelectedMailboxView(account: account, selectedMailbox: selectedMailbox)
            }

            Button(MailResourcesStrings.Localizable.buttonContinue, action: viewModel.validateMailboxChoice)
                .buttonStyle(.ikPlain)
                .controlSize(.large)
                .ikButtonFullWidth(true)
        }
        .padding(.horizontal, value: .medium)
        .padding(.bottom, UIPadding.onBoardingBottomButtons)
        .mailboxCellStyle(.account)
        .matomoView(view: [MatomoUtils.View.bottomSheet.displayName, "SelectComposeMailboxView"])
    }
}

#Preview {
    SelectComposeMailboxView(
        composeMessageIntent: .constant(.new()),
        viewModel: SelectComposeMailboxViewModel(composeMessageIntent: .constant(.new()))
    )
}
