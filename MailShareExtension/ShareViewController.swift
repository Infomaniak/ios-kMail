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
import Social
import SwiftUI
import UIKit

class ShareNavigationViewController: TitleSizeAdjustingNavigationController {
    override public func viewDidLoad() {
        super.viewDidLoad()

        // Modify sheet size on iPadOS, property is ignored on iOS
        preferredContentSize = CGSize(width: 540, height: 620)

        guard let attachments = (extensionContext?.inputItems.first as? NSExtensionItem)?.attachments else {
            dismiss(animated: true)
            return
        }
        
        // To my knowledge, we need to go threw wrapping to use SwiftUI here.
        let childView = UIHostingController(rootView: SwiftUIView())
        addChild(childView)
        childView.view.frame = self.view.bounds
        self.view.addSubview(childView.view)
        childView.didMove(toParent: self)
    }

    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        extensionContext!.completeRequest(returningItems: nil, completionHandler: nil)
    }
}

struct SwiftUIView: View {
    var body: some View {
        Text("test")
            .background(.red)
    }
}
