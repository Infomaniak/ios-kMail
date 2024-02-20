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
import InfomaniakDI
import MailCore
import MailResources
import NavigationBackport
import SwiftUI

struct SelectComposeMailboxView: View {
    @LazyInjectService private var accountManager: AccountManager
    @LazyInjectService private var mailboxInfosManager: MailboxInfosManager
    @LazyInjectService private var platformDetector: PlatformDetectable

    @Environment(\.dismiss) private var dismiss
    @Environment(\.dismissModal) var dismissModal

    @AppStorage(UserDefaults.shared.key(.accentColor)) private var accentColor = DefaultPreferences.accentColor

    @StateObject private var viewModel: SelectComposeMailboxViewModel

    @Binding var composeMessageIntent: ComposeMessageIntent

    init(composeMessageIntent: Binding<ComposeMessageIntent>) {
        _composeMessageIntent = composeMessageIntent
        _viewModel = StateObject(wrappedValue: SelectComposeMailboxViewModel(composeMessageIntent: composeMessageIntent))
    }

    var body: some View {
        VStack(spacing: 0) {
            accentColor.mailTo.swiftUIImage

            Text(MailResourcesStrings.Localizable.mailToTitle(""))
                .textStyle(.header1)
                .multilineTextAlignment(.center)
                .padding(.bottom, value: .medium)

            Text(MailResourcesStrings.Localizable.mailToDescription)
                .textStyle(.bodySmallSecondary)
                .padding(.bottom, value: .regular)
                .frame(maxWidth: .infinity, alignment: .leading)

            ScrollView {
                ForEach(viewModel.accounts) { account in
                    AccountMailboxesListView(
                        account: account,
                        selectedMailbox: viewModel.selectedMailbox,
                        selectMailbox: viewModel.selectMailbox
                    )
                }
            }

            Button(MailResourcesStrings.Localizable.buttonContinue, action: viewModel.validateMailboxChoice)
                .buttonStyle(.ikPlain)
                .controlSize(.large)
                .ikButtonFullWidth(true)
        }
        .padding(.horizontal, value: .medium)
        .mailboxCellStyle(.account)
        .onAppear(perform: viewModel.initDefaultAccountAndMailbox)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if !platformDetector.isMac {
                    CloseButton(dismissHandler: dismissMessageView)
                }
            }
        }
    }

    private func dismissMessageView() {
        dismissModal()
        dismiss()
    }
}

#Preview {
    SelectComposeMailboxView(composeMessageIntent: .constant(.new()))
}

enum TestTest {
    case test
}