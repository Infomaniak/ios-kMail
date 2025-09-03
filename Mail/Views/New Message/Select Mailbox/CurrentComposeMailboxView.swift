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
import InfomaniakCoreCommonUI
import InfomaniakCoreSwiftUI
import InfomaniakDI
import MailCore
import MailCoreUI
import MailResources
import NavigationBackport
import SwiftUI

struct CurrentComposeMailboxView: View {
    @InjectService private var platformDetector: PlatformDetectable

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
        NavigationView {
            VStack(spacing: 0) {
                accentColor.mailboxImage.swiftUIImage
                    .padding(.bottom, value: .medium)

                Text(MailResourcesStrings.Localizable.composeMailboxCurrentTitle)
                    .textStyle(.header2)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, value: .large)

                if let defaultSelectableMailbox = viewModel.defaultSelectableMailbox {
                    SelectedMailboxView(
                        selectedUser: defaultSelectableMailbox.user,
                        selectedMailboxManager: defaultSelectableMailbox.mailboxManager
                    )
                    .frame(maxHeight: .infinity, alignment: .top)
                }

                VStack(spacing: IKPadding.medium) {
                    Button(MailResourcesStrings.Localizable.buttonContinue) {
                        viewModel.validateMailboxChoice(viewModel.defaultSelectableMailbox?.mailbox)
                    }
                    .buttonStyle(.ikBorderedProminent)

                    NavigationLink(destination: SelectComposeMailboxView(
                        composeMessageIntent: $composeMessageIntent,
                        viewModel: viewModel
                    )) {
                        Text(MailResourcesStrings.Localizable.buttonSendWithDifferentAddress)
                            .textStyle(.bodyMediumAccent)
                    }
                    .buttonStyle(.ikBorderless)
                    .padding(.bottom, IKPadding.onBoardingBottomButtons)
                }
                .ikButtonFullWidth(true)
                .controlSize(.large)
                .padding(.horizontal, value: .mini)
            }
            .padding(.horizontal, value: .medium)
            .mailboxCellStyle(.account)
            .task {
                await viewModel.initProfilesSelectDefaultAccountAndMailbox()
            }
            .backButtonDisplayMode(.minimal)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !platformDetector.isMac || platformDetector.isInExtension || platformDetector.isLegacyMacCatalyst {
                        ToolbarCloseButton(dismissHandler: dismissMessageView)
                    }
                }
            }
            .matomoView(view: [MatomoUtils.View.bottomSheet.displayName, "CurrentComposeMailboxView"])
        }
    }

    private func dismissMessageView() {
        dismissModal()
        dismiss()
    }
}

#Preview {
    CurrentComposeMailboxView(composeMessageIntent: .constant(.new()))
}
