//
//  ViewController.swift
//  mail
//
//  Created by Ambroise Decouttere on 08/02/2022.
//

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

