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

import InfomaniakLogin
import MailCore
import SwiftUI
import UIKit

struct LoginView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> LoginViewController {
        let login = LoginViewController.instantiate()
        return login
    }

    func updateUIViewController(_ uiViewController: LoginViewController, context: Context) {
        // Intentionally unimplemented...
    }
}

class LoginViewController: UIViewController {
    override func viewDidLoad() {
        InfomaniakLogin.setupWebviewNavbar(
            title: "",
            titleColor: nil,
            color: nil,
            buttonColor: nil,
            clearCookie: true,
            timeOutMessage: "Timeout"
        )
    }

    @IBAction func loginButtonPressed(_ sender: UIButton) {
        InfomaniakLogin.webviewLoginFrom(viewController: self, delegate: self)
    }

    static func instantiate() -> LoginViewController {
        return UIStoryboard(name: "Main", bundle: nil)
            .instantiateViewController(withIdentifier: "LoginViewController") as! LoginViewController
    }
}

extension LoginViewController: InfomaniakLoginDelegate {
    func didCompleteLoginWith(code: String, verifier: String) {
        MatomoUtils.track(eventWithCategory: .account, name: "loggedIn")
        let previousAccount = AccountManager.instance.currentAccount
        Task {
            do {
                _ = try await AccountManager.instance.createAndSetCurrentAccount(code: code, codeVerifier: verifier)
                MatomoUtils.connectUser()
                let splitView = SplitView().environment(\.window, self.view.window)
                let splitVC = UIHostingController(rootView: splitView)
                self.view.window?.rootViewController = splitVC
                self.view.window?.makeKeyAndVisible()
            } catch {
                if previousAccount != nil {
                    AccountManager.instance.switchAccount(newAccount: previousAccount!)
                }
            }
        }
    }

    func didFailLoginWith(error: String) {
        // Handle the error
    }
}
