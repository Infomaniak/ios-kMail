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

import InfomaniakCoreUI
import InfomaniakCreateAccount
import InfomaniakDI
import InfomaniakLogin
import MailCore
import MailResources
import SwiftUI

struct CreateAccountView: View {
    @AppStorage(UserDefaults.shared.key(.accentColor)) private var accentColor = DefaultPreferences.accentColor

    @State private var isPresentingCreateAccount = false

    @ObservedObject var loginHandler: LoginHandler

    var body: some View {
        VStack(spacing: 0) {
            accentColor.createAccountImage.swiftUIImage
                .resizable()
                .scaledToFit()
                .padding(.top, value: .medium)
                .padding(.bottom, value: .large)

            Text(MailResourcesStrings.Localizable.newAccountTitle)
                .textStyle(.header1)
                .multilineTextAlignment(.center)
                .padding(.bottom, value: .medium)

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
            .padding(.bottom, value: .medium)

            Text(MailResourcesStrings.Localizable.newAccountDescription)
                .textStyle(.bodySmallSecondary)
                .padding(.bottom, value: .medium)
                .multilineTextAlignment(.center)

            Spacer()

            MailButton(label: MailResourcesStrings.Localizable.buttonStart) {
                @InjectService var matomo: MatomoUtils
                matomo.track(eventWithCategory: .account, name: "openCreationWebview")
                isPresentingCreateAccount = true
            }
            .mailButtonFullWidth(true)
            .mailButtonLoading(loginHandler.isLoading)
            .padding(.bottom, value: .regular)
        }
        .padding(.horizontal, value: .medium)
        .sheet(isPresented: $isPresentingCreateAccount) {
            RegisterView(registrationProcess: .mail) { viewController in
                guard let viewController else { return }
                loginHandler.loginAfterAccountCreation(from: viewController)
            }
        }
        .matomoView(view: [MatomoUtils.View.onboarding.displayName, "CreateAccount"])
    }
}

struct CreateAccountView_Previews: PreviewProvider {
    static var previews: some View {
        CreateAccountView(loginHandler: LoginHandler())
    }
}
