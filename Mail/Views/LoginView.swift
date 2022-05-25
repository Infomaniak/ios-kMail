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

import AuthenticationServices
import InfomaniakLogin
import MailCore
import MailResources
import SwiftUI

struct LoginView: View {
    var isPresented: Binding<Bool>?

    @State private var presentAlert = false

    @Environment(\.window) var window

    var body: some View {
        NavigationView {
            VStack(spacing: 8) {
                Spacer()
                Group {
                    Image(resource: MailResourcesAsset.welcome)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 185)
                    Text("Bienvenue sur l’App Mail Infomaniak")
                        .textStyle(.header3)
                        .padding(.top, 48)
                    Text("Connectez-vous à votre compte et gérez tous vos emails Infomaniak depuis l’app.")
                        .textStyle(.callout)
                }
                Spacer()
                Button("Connexion") {
                    InfomaniakLogin.asWebAuthenticationLoginFrom(useEphemeralSession: true) { result in
                        switch result {
                        case .success(let result):
                            loginSuccessful(code: result.code, codeVerifier: result.verifier)
                        case .failure(let error):
                            loginFailed(error: error)
                        }
                    }
                }
                .textStyle(.button)
                Spacer()
            }
            .padding(48)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Group {
                if let isPresented = isPresented {
                    Button {
                        isPresented.wrappedValue = false
                    } label: {
                        Image(systemName: "xmark")
                            .tint(MailResourcesAsset.primaryTextColor)
                    }
                } else {
                    EmptyView()
                }
            })
            .alert("Erreur", isPresented: $presentAlert) {} message: {
                Text("La connexion a échoué.")
            }
        }
    }

    // MARK: - Private methods

    private func loginSuccessful(code: String, codeVerifier verifier: String) {
        MatomoUtils.track(eventWithCategory: .account, name: "loggedIn")
        let previousAccount = AccountManager.instance.currentAccount
        Task {
            do {
                _ = try await AccountManager.instance.createAndSetCurrentAccount(code: code, codeVerifier: verifier)
                MatomoUtils.connectUser()
                await (self.window?.windowScene?.delegate as? SceneDelegate)?.showMainView()
            } catch {
                if let previousAccount = previousAccount {
                    AccountManager.instance.switchAccount(newAccount: previousAccount)
                }
            }
        }
    }

    private func loginFailed(error: Error) {
        print("Login error: \(error)")
        guard (error as? ASWebAuthenticationSessionError)?.code != .canceledLogin else { return }
        presentAlert = true
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
        LoginView(isPresented: .constant(true))
    }
}
