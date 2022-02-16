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

import MailCore
import UIKit

class MessageListViewController: UICollectionViewController {
    var dataTest = ["Message 1", "Message 2", "Message 3"]
    var selectedMailbox = ""

    // MARK: - Public methods

    convenience init() {
        self.init(collectionViewLayout: Self.createLayout())
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "cell")
    }

    // MARK: - Private methods

    private static func createLayout() -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout { _, _ in
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(53))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            let group = NSCollectionLayoutGroup.vertical(layoutSize: itemSize, subitems: [item])
            return NSCollectionLayoutSection(group: group)
        }
    }
}

// MARK: - UICollectionViewDataSource

extension MessageListViewController {
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataTest.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        let data = dataTest[indexPath.item]
        let titleLabel = UILabel(frame: CGRect(x: 20, y: 0, width: cell.bounds.size.width - 40, height: 40))
        titleLabel.textColor = UIColor.black
        titleLabel.text = selectedMailbox + " - " + data
        titleLabel.textAlignment = .left
        cell.contentView.addSubview(titleLabel)
        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension MessageListViewController {
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedThread = dataTest[indexPath.item]
        let threadVC = ThreadViewController()
        threadVC.selectedThread = selectedThread
        self.showDetailViewController(threadVC, sender: self)
      }
}
