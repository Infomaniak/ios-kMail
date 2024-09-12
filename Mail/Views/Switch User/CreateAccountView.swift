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
import InfomaniakCreateAccount
import InfomaniakDI
import InfomaniakLogin
import MailCore
import MailCoreUI
import MailResources
import SwiftModalPresentation
import SwiftUI

struct CreateAccountView: View {
    @LazyInjectService private var matomo: MatomoUtils

    @AppStorage(UserDefaults.shared.key(.accentColor)) private var accentColor = DefaultPreferences.accentColor

    @Environment(\.dismiss) private var dismiss

    @ModalState(context: ContextKeys.createAccount) private var isPresentingCreateAccount = false

    @ObservedObject var loginHandler: LoginHandler

    var body: some View {
        VStack(spacing: 0) {
            CloseButton(size: .medium, dismissAction: dismiss)
                .padding(.top, IKPadding.onBoardingLogoTop)
                .padding(.top, value: .extraSmall)
                .frame(maxWidth: .infinity, alignment: .leading)

            accentColor.createAccountImage.swiftUIImage
                .resizable()
                .scaledToFit()
                .padding(.top, value: .large)
                .padding(.bottom, value: .extraLarge)

            Text(MailResourcesStrings.Localizable.newAccountTitle)
                .textStyle(.header1)
                .multilineTextAlignment(.center)
                .padding(.bottom, value: .large)

            HStack {
                Text(MailResourcesStrings.Localizable.newAccountStorageMail)
                    .textStyle(.labelMediumAccent)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(value: .small)
                    .background(accentColor.secondary.swiftUIColor)
                    .clipShape(Capsule())
                    .multilineTextAlignment(.center)
                Text(MailResourcesStrings.Localizable.newAccountStorageDrive)
                    .textStyle(.labelMediumAccent)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(value: .small)
                    .background(accentColor.secondary.swiftUIColor)
                    .clipShape(Capsule())
                    .multilineTextAlignment(.center)
            }
            .fixedSize(horizontal: false, vertical: true)
            .padding(.bottom, value: .large)

            Text(MailResourcesStrings.Localizable.newAccountDescription)
                .textStyle(.bodySmallSecondary)
                .padding(.bottom, value: .large)
                .multilineTextAlignment(.center)

            Spacer()

            Button(MailResourcesStrings.Localizable.buttonStart) {
                matomo.track(eventWithCategory: .account, name: "openCreationWebview")
                isPresentingCreateAccount = true
            }
            .buttonStyle(.ikBorderedProminent)
            .ikButtonLoading(loginHandler.isLoading)
            .ikButtonFullWidth(true)
            .controlSize(.large)
            .padding(.bottom, value: .medium)
        }
        .padding(.horizontal, value: .large)
        .sheet(isPresented: $isPresentingCreateAccount) {
            RegisterView(registrationProcess: .mail) { viewController in
                guard let viewController else { return }
                loginHandler.loginAfterAccountCreation(from: viewController)
            }
        }
        .matomoView(view: [MatomoUtils.View.onboarding.displayName, "CreateAccount"])
    }
}

#Preview {
    CreateAccountView(loginHandler: LoginHandler())
}
