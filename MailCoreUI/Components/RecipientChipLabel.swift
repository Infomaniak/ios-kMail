/*
 Infomaniak Mail - iOS App
 Copyright (C) 2023 Infomaniak Network SA

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import Foundation
import InfomaniakCoreUI
import MailCore
import MailResources
import SwiftUI
import UIKit

public struct RecipientChipLabelView: UIViewRepresentable {
    @Environment(\.isEnabled) private var isEnabled: Bool
    @EnvironmentObject private var mailboxManager: MailboxManager

    let recipient: Recipient
    let removeHandler: (() -> Void)?
    let switchFocusHandler: (() -> Void)?

    public init(
        recipient: Recipient,
        removeHandler: (() -> Void)? = nil,
        switchFocusHandler: (() -> Void)? = nil
    ) {
        self.recipient = recipient
        self.removeHandler = removeHandler
        self.switchFocusHandler = switchFocusHandler
    }

    public func makeUIView(context: Context) -> RecipientChipLabel {
        let label = RecipientChipLabel(recipient: recipient, external: recipient.isExternal(mailboxManager: mailboxManager))
        label.removeHandler = removeHandler
        label.switchFocusHandler = switchFocusHandler
        label.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        label.setContentHuggingPriority(.defaultHigh, for: .vertical)
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return label
    }

    public func updateUIView(_ uiLabel: RecipientChipLabel, context: Context) {
        uiLabel.text = recipient.name.isEmpty ? recipient.email : recipient.name
        uiLabel.isExternal = recipient.isExternal(mailboxManager: mailboxManager)
        uiLabel.isUserInteractionEnabled = isEnabled
        uiLabel.updateColors(isFirstResponder: uiLabel.isFirstResponder)
    }
}

public class RecipientChipLabel: UILabel, UIKeyInput {
    var removeHandler: (() -> Void)?
    var switchFocusHandler: (() -> Void)?

    override public var intrinsicContentSize: CGSize {
        var contentSize = super.intrinsicContentSize
        contentSize.height += IKPadding.recipientChip.top + IKPadding.recipientChip.bottom
        contentSize.width += IKPadding.recipientChip.left + IKPadding.recipientChip.right
        return contentSize
    }

    override public var canBecomeFirstResponder: Bool { return isUserInteractionEnabled }

    public var hasText = false
    var isExternal = false

    public init(recipient: Recipient, external: Bool) {
        super.init(frame: .zero)

        text = recipient.name.isEmpty ? recipient.email : recipient.name
        textAlignment = .center
        numberOfLines = 1

        font = .systemFont(ofSize: 16)

        layer.cornerRadius = intrinsicContentSize.height / 2
        layer.borderWidth = 1
        layer.masksToBounds = true

        isExternal = external
        updateColors(isFirstResponder: false)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: IKPadding.recipientChip))
    }

    override public func becomeFirstResponder() -> Bool {
        updateColors(isFirstResponder: true)
        return super.becomeFirstResponder()
    }

    override public func resignFirstResponder() -> Bool {
        updateColors(isFirstResponder: false)
        return super.resignFirstResponder()
    }

    public func insertText(_ text: String) {
        if text == "\t" {
            switchFocusHandler?()
        }
    }

    public func deleteBackward() {
        removeHandler?()
    }

    public func updateColors(isFirstResponder: Bool) {
        if isExternal {
            textColor = isFirstResponder ? MailResourcesAsset.onTagExternalColor.color : MailResourcesAsset.textPrimaryColor.color
            borderColor = MailResourcesAsset.yellowColor.color
            backgroundColor = isFirstResponder ? MailResourcesAsset.yellowColor.color : MailResourcesAsset.textFieldColor.color
        } else {
            textColor = isFirstResponder ? UserDefaults.shared.accentColor.secondary.color : .tintColor
            borderColor = isFirstResponder ? UserDefaults.shared.accentColor.primary.color : UserDefaults.shared.accentColor
                .secondary.color
            backgroundColor = isFirstResponder ? .tintColor : UserDefaults.shared.accentColor.secondary.color
        }
    }
}
