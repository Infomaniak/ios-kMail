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

import InfomaniakCore
import InfomaniakCoreUI
import InfomaniakDI
import MailCore
import MailResources
import NavigationBackport
import SwiftUI

struct SelectComposeMailboxView: View {
    @LazyInjectService private var accountManager: AccountManager

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
                .padding(.bottom, value: .regular)

            ScrollView {
                VStack(spacing: 0) {
                    ForEach(viewModel.accounts) { account in
                        AccountMailboxesListView(
                            account: account,
                            selectedMailbox: viewModel.selectedMailbox,
                            selectMailbox: viewModel.selectMailbox
                        )
                        .padding(.top, value: .small)
                    }
                }
            }

            if let selectedMailbox = viewModel.selectedMailbox,
               let mailboxManager = accountManager.getMailboxManager(for: selectedMailbox) {
                SelectedMailboxView(selectedMailboxManager: mailboxManager)
                    .padding(.horizontal, value: .small)
                    .padding(.bottom, value: .regular)
            }

            Button(MailResourcesStrings.Localizable.buttonContinue) {
                viewModel.validateMailboxChoice(viewModel.selectedMailbox)
            }
            .buttonStyle(.ikPlain)
            .controlSize(.large)
            .ikButtonFullWidth(true)
            .padding(.horizontal, value: .small)
            .disabled(!viewModel.selectionMade)
        }
        .padding(.horizontal, value: .regular)
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
