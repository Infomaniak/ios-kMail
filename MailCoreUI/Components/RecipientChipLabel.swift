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

import DesignSystem
import Foundation
import InfomaniakCoreSwiftUI
import MailCore
import MailResources
import SwiftUI
import UIKit

public struct RecipientChipLabelView<Accessory: View>: UIViewRepresentable {
    @Environment(\.isEnabled) private var isEnabled: Bool
    @EnvironmentObject private var mailboxManager: MailboxManager

    let recipient: Recipient

    let removeHandler: (() -> Void)?
    let switchFocusHandler: (() -> Void)?

    let accessory: Accessory?

    public init(
        recipient: Recipient,
        removeHandler: (() -> Void)? = nil,
        switchFocusHandler: (() -> Void)? = nil,
        @ViewBuilder accessory: () -> Accessory
    ) {
        self.recipient = recipient
        self.removeHandler = removeHandler
        self.switchFocusHandler = switchFocusHandler
        self.accessory = accessory()
    }

    public func makeUIView(context: Context) -> RecipientChipLabel {
        let label = RecipientChipLabel(recipient: recipient, external: recipient.isExternal(mailboxManager: mailboxManager))
        label.removeHandler = removeHandler
        label.switchFocusHandler = switchFocusHandler
        label.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        label.setContentHuggingPriority(.defaultHigh, for: .vertical)
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        if let accessory {
            label.accessoryView = transformAccessoryForUIKit(accessory)
        }

        return label
    }

    public func updateUIView(_ uiLabel: RecipientChipLabel, context: Context) {
        uiLabel.text = recipient.name.isEmpty ? recipient.email : recipient.name
        uiLabel.isExternal = recipient.isExternal(mailboxManager: mailboxManager)
        uiLabel.isUserInteractionEnabled = isEnabled

        if let accessory {
            uiLabel.accessoryView = transformAccessoryForUIKit(accessory)
        } else {
            uiLabel.accessoryView = nil
        }
        uiLabel.invalidateIntrinsicContentSize()
    }

    private func transformAccessoryForUIKit<Content: View>(_ view: Content) -> UIView? {
        let uiView = UIHostingController(rootView: view).view
        uiView?.backgroundColor = .clear
        return uiView
    }
}

public extension RecipientChipLabelView where Accessory == Never {
    init(
        recipient: Recipient,
        removeHandler: (() -> Void)? = nil,
        switchFocusHandler: (() -> Void)? = nil
    ) {
        self.recipient = recipient
        self.removeHandler = removeHandler
        self.switchFocusHandler = switchFocusHandler
        accessory = nil
    }
}

public class RecipientChipLabel: UIView, UIKeyInput {
    var text: String? {
        get { label.text }
        set { label.text = newValue }
    }

    var accessoryView: UIView? {
        willSet {
            toggleAccessoryView(accessoryView, newValue)
        }
    }

    var spacing: CGFloat = 4.0

    var isExternal = false

    var removeHandler: (() -> Void)?
    var switchFocusHandler: (() -> Void)?

    override public var intrinsicContentSize: CGSize {
        var labelSize = label.intrinsicContentSize
        labelSize.height += IKPadding.recipientChip.top + IKPadding.recipientChip.bottom
        labelSize.width += IKPadding.recipientChip.left + IKPadding.recipientChip.right

        var accessoryViewSize = CGSize.zero
        if let accessoryViewIntrinsicSize = accessoryView?.intrinsicContentSize, accessoryViewIntrinsicSize != .zero {
            accessoryViewSize = CGSize(
                width: accessoryViewIntrinsicSize.width + spacing,
                height: accessoryViewIntrinsicSize.height
            )
        }

        return CGSize(
            width: labelSize.width + accessoryViewSize.width,
            height: max(labelSize.height, accessoryViewSize.height)
        )
    }

    override public var canBecomeFirstResponder: Bool { return isUserInteractionEnabled }

    override public func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.userInterfaceStyle != previousTraitCollection?.userInterfaceStyle {
            updateColors(isFirstResponder: false)
        }
    }

    public var hasText = false

    private let label: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 1
        label.font = .systemFont(ofSize: 16)
        return label
    }()

    private var accessoryViewConstraints = [NSLayoutConstraint]()

    public init(recipient: Recipient, external: Bool) {
        super.init(frame: .zero)

        label.text = recipient.name.isEmpty ? recipient.email : recipient.name

        isExternal = external
        updateColors(isFirstResponder: false)

        setupView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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

    private func updateColors(isFirstResponder: Bool) {
        if isExternal {
            label.textColor = isFirstResponder ? MailResourcesAsset.onTagExternalColor.color : MailResourcesAsset.textPrimaryColor
                .color
            borderColor = MailResourcesAsset.yellowColor.color
            backgroundColor = isFirstResponder ? MailResourcesAsset.yellowColor.color : MailResourcesAsset.textFieldColor.color
        } else {
            label.textColor = isFirstResponder ? UserDefaults.shared.accentColor.secondary.color : .tintColor
            borderColor = isFirstResponder ? UserDefaults.shared.accentColor.primary.color : UserDefaults.shared.accentColor
                .secondary.color
            backgroundColor = isFirstResponder ? .tintColor : UserDefaults.shared.accentColor.secondary.color
        }
    }

    private func setupView() {
        translatesAutoresizingMaskIntoConstraints = false

        layer.cornerRadius = intrinsicContentSize.height / 2
        layer.borderWidth = 1
        layer.masksToBounds = true

        addSubview(label)

        NSLayoutConstraint.activate([
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -IKPadding.recipientChip.right),
            label.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    private func toggleAccessoryView(_ oldValue: UIView?, _ newValue: UIView?) {
        if let oldValue {
            willRemoveSubview(oldValue)
            oldValue.removeFromSuperview()

            NSLayoutConstraint.deactivate(accessoryViewConstraints)
            accessoryViewConstraints = []
        }

        if let newValue, newValue.intrinsicContentSize != .zero {
            newValue.translatesAutoresizingMaskIntoConstraints = false
            addSubview(newValue)

            accessoryViewConstraints = getConstraints(forAccessory: newValue)
            NSLayoutConstraint.activate(accessoryViewConstraints)
        }
    }

    private func getConstraints(forAccessory view: UIView) -> [NSLayoutConstraint] {
        return [
            view.leadingAnchor.constraint(equalTo: leadingAnchor, constant: IKPadding.recipientChip.left),
            view.centerYAnchor.constraint(equalTo: centerYAnchor),
            view.trailingAnchor.constraint(equalTo: label.leadingAnchor, constant: -spacing)
        ]
    }
}

@available(iOS 17.0, *)
#Preview {
    @Previewable @State var isShowingAccessory = true

    VStack {
        RecipientChipLabelView(recipient: PreviewHelper.sampleRecipient1) {} switchFocusHandler: {}

        RecipientChipLabelView(recipient: PreviewHelper.sampleRecipient1) {} switchFocusHandler: {} accessory: {
            if isShowingAccessory {
                Image(systemName: "lock")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.tint)
                    .frame(width: 12, height: 12)
            }
        }
        .onTapGesture {
            isShowingAccessory.toggle()
        }
    }
    .environmentObject(PreviewHelper.sampleMailboxManager)
    .tint(UserDefaults.shared.accentColor.primary.swiftUIColor)
}
