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

import Foundation
import MailCore
import SwiftUI
import UIKit

struct RecipientChipLabelView: UIViewRepresentable {
    let recipient: Recipient
    let removeHandler: () -> Void
    let switchFocusHandler: () -> Void

    func makeUIView(context: Context) -> RecipientChipLabel {
        let label = RecipientChipLabel(recipient: recipient)
        label.removeHandler = removeHandler
        label.switchFocusHandler = switchFocusHandler
        return label
    }

    func updateUIView(_ uiLabel: RecipientChipLabel, context: Context) {
        uiLabel.text = recipient.name.isEmpty ? recipient.email : recipient.name
    }
}

class RecipientChipLabel: UILabel, UIKeyInput {
    var removeHandler: (() -> Void)?
    var switchFocusHandler: (() -> Void)?

    override var intrinsicContentSize: CGSize {
        var contentSize = super.intrinsicContentSize
        contentSize.height += UIConstants.chipInsets.top + UIConstants.chipInsets.bottom
        contentSize.width += UIConstants.chipInsets.left + UIConstants.chipInsets.right
        return contentSize
    }

    override var canBecomeFirstResponder: Bool { return true }

    var hasText = false

    init(recipient: Recipient) {
        super.init(frame: .zero)

        text = recipient.name.isEmpty ? recipient.email : recipient.name
        textAlignment = .center
        numberOfLines = 1

        font = .systemFont(ofSize: 16)
        updateColors(isFirstResponder: false)

        layer.cornerRadius = intrinsicContentSize.height / 2
        layer.masksToBounds = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: UIConstants.chipInsets))
    }

    override func becomeFirstResponder() -> Bool {
        updateColors(isFirstResponder: true)
        return super.becomeFirstResponder()
    }

    override func resignFirstResponder() -> Bool {
        updateColors(isFirstResponder: false)
        return super.resignFirstResponder()
    }

    func insertText(_ text: String) {
        if text == "\t" {
            switchFocusHandler?()
        }
    }

    func deleteBackward() {
        removeHandler?()
    }

    private func updateColors(isFirstResponder: Bool) {
        textColor = isFirstResponder ? UserDefaults.shared.accentColor.secondary.color : .tintColor
        backgroundColor = isFirstResponder ? .tintColor : UserDefaults.shared.accentColor.secondary.color
    }
}
