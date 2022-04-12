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

class LoginViewController: UIViewController {
    @IBAction func loginButtonPressed(_ sender: UIButton) {
        InfomaniakLogin.initWith(
            clientId: "E90BC22D-67A8-452C-BE93-28DA33588CA4",
            redirectUri: "com.infomaniak.mail://oauth2redirect"
        )
        InfomaniakLogin.webviewLoginFrom(viewController: self, delegate: self)
    }
}

extension LoginViewController: InfomaniakLoginDelegate {
    func didCompleteLoginWith(code: String, verifier: String) {
        let previousAccount = AccountManager.instance.currentAccount
        Task {
            do {
                _ = try await AccountManager.instance.createAndSetCurrentAccount(code: code, codeVerifier: verifier)
                MatomoUtils.connectUser()
                let splitVC = UIHostingController(rootView: SplitView())
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
