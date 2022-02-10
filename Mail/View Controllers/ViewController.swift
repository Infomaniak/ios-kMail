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

import UIKit
import InfomaniakLogin

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    @IBAction func loginButtonPressed(_ sender: UIButton) {
        InfomaniakLogin.initWith(clientId: "E90BC22D-67A8-452C-BE93-28DA33588CA4", redirectUri: "com.infomaniak.mail://oauth2redirect")
        InfomaniakLogin.webviewLoginFrom(viewController: self, delegate: self)
    }
    
}

extension ViewController: InfomaniakLoginDelegate {
    func didCompleteLoginWith(code: String, verifier: String) {
        InfomaniakLogin.getApiTokenUsing(code: code, codeVerifier: verifier) { (token, error) in
            // Save the token
            guard let token = token else {
                return
            }

            AccountManager.instance.createAndSetCurrentAccount(token: token)
            
            DispatchQueue.main.async {
                let mailboxesVC = MessageListViewController.instantiate()
                mailboxesVC.modalPresentationStyle = .fullScreen
                self.present(mailboxesVC, animated: true, completion: nil)
            }
        }
    }
    
    func didFailLoginWith(error: String) {
        // Handle the error
    }
    
    
}

