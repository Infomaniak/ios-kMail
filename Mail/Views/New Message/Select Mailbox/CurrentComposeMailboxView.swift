/*
 Infomaniak Mail - iOS App
 Copyright (C) 2024 Infomaniak Network SA

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

struct CurrentComposeMailboxView: View {
    @LazyInjectService private var accountManager: AccountManager
    @LazyInjectService private var matomo: MatomoUtils
    @LazyInjectService private var platformDetector: PlatformDetectable

    @AppStorage(UserDefaults.shared.key(.accentColor)) private var accentColor = DefaultPreferences.accentColor

    @Environment(\.dismiss) private var dismiss
    @Environment(\.dismissModal) private var dismissModal

    @StateObject private var viewModel: SelectComposeMailboxViewModel

    @Binding var composeMessageIntent: ComposeMessageIntent

    init(composeMessageIntent: Binding<ComposeMessageIntent>) {
        _composeMessageIntent = composeMessageIntent
        _viewModel = StateObject(wrappedValue: SelectComposeMailboxViewModel(composeMessageIntent: composeMessageIntent))
    }

    var body: some View {
        VStack(spacing: 0) {
            accentColor.mailboxImage.swiftUIImage
                .padding(.bottom, value: .regular)

            Text(MailResourcesStrings.Localizable.composeMailboxCurrentTitle)
                .textStyle(.header2)
                .multilineTextAlignment(.center)
                .padding(.bottom, value: .medium)

            if let selectedMailbox = viewModel.selectedMailbox,
               let account = accountManager.account(for: selectedMailbox.userId) {
                SelectedMailboxView(account: account, selectedMailbox: selectedMailbox)
                    .frame(maxHeight: .infinity, alignment: .top)
            }

            VStack(spacing: UIPadding.regular) {
                Button(MailResourcesStrings.Localizable.buttonContinue, action: viewModel.validateMailboxChoice)
                    .buttonStyle(.ikPlain)
                    .ikButtonFullWidth(true)
                    .controlSize(.large)

                NavigationLink(destination: SelectComposeMailboxView(
                    composeMessageIntent: $composeMessageIntent,
                    viewModel: viewModel
                )) {
                    Text("Envoyer avec une autre adresse")
                        .textStyle(.bodyMediumAccent)
                }
            }
        }
        .padding(.horizontal, value: .medium)
        .mailboxCellStyle(.account)
        .onAppear(perform: viewModel.initDefaultAccountAndMailbox)
        .backButtonDisplayMode(.minimal)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if !platformDetector.isMac {
                    CloseButton(dismissHandler: dismissMessageView)
                }
            }
        }
        .matomoView(view: [MatomoUtils.View.bottomSheet.displayName, "CurrentComposeMailboxView"])
    }

    private func dismissMessageView() {
        dismissModal()
        dismiss()
    }
}

#Preview {
    CurrentComposeMailboxView(composeMessageIntent: .constant(.new()))
}
