//
//  MessageListViewController.swift
//  mail
//
//  Created by Ambroise Decouttere on 08/02/2022.
//

import UIKit

class MessageListViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(HostingTableViewCell<MessageListView>.self, forCellReuseIdentifier: "messageCell")
    }
    
    static func instantiate() -> MessageListViewController {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MessageListViewController") as! MessageListViewController
    }
}

extension MessageListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "messageCell") as! HostingTableViewCell<MessageListView>
        cell.host(MessageListView(), parent: self)
        return cell
    }
}
