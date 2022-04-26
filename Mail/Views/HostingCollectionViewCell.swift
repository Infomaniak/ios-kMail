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

import MailResources
import UIKit
import SwiftUI

class HostingCollectionViewCell<Content: View>: UICollectionViewCell {
    private weak var controller: UIHostingController<Content>?

    func host(_ view: Content, parent: UIViewController) {
        if let controller = controller {
            controller.rootView = view
            controller.view.layoutIfNeeded()
        } else {
            let hostingController = UIHostingController(rootView: view)
            controller = hostingController
            hostingController.view.backgroundColor = .clear

            parent.addChild(hostingController)

            hostingController.view.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(hostingController.view)
            contentView.addConstraint(NSLayoutConstraint(item: hostingController.view!, attribute: .leading, relatedBy: .equal, toItem: contentView, attribute: .leading, multiplier: 1, constant: 0))
            contentView.addConstraint(NSLayoutConstraint(item: hostingController.view!, attribute: .trailing, relatedBy: .equal, toItem: contentView, attribute: .trailing, multiplier: 1, constant: 0))
            contentView.addConstraint(NSLayoutConstraint(item: hostingController.view!, attribute: .top, relatedBy: .equal, toItem: contentView, attribute: .top, multiplier: 1, constant: 0))
            contentView.addConstraint(NSLayoutConstraint(item: hostingController.view!, attribute: .bottom, relatedBy: .equal, toItem: contentView, attribute: .bottom, multiplier: 1, constant: 0))

            hostingController.didMove(toParent: parent)
            hostingController.view.layoutIfNeeded()
        }

        let selectedView = UIView(frame: bounds)
        selectedView.backgroundColor = MailResourcesAsset.backgroundHeaderColor.color
        selectedBackgroundView = selectedView

        focusEffect = .none
    }
}
