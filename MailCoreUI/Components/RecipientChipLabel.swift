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
    var type: RecipientChipType

    let removeHandler: (() -> Void)?
    let switchFocusHandler: (() -> Void)?

    let accessory: Accessory?

    public init(
        recipient: Recipient,
        type: RecipientChipType = .default,
        removeHandler: (() -> Void)? = nil,
        switchFocusHandler: (() -> Void)? = nil,
        @ViewBuilder accessory: () -> Accessory
    ) {
        self.recipient = recipient
        self.type = type
        self.removeHandler = removeHandler
        self.switchFocusHandler = switchFocusHandler
        self.accessory = accessory()
    }

    public func makeUIView(context: Context) -> RecipientChipLabel {
        let label = RecipientChipLabel(recipient: recipient, type: type)
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
        uiLabel.type = type
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
        type: RecipientChipType,
        removeHandler: (() -> Void)? = nil,
        switchFocusHandler: (() -> Void)? = nil
    ) {
        self.recipient = recipient
        self.type = type
        self.removeHandler = removeHandler
        self.switchFocusHandler = switchFocusHandler
        accessory = nil
    }
}

struct RecipientChipTheme {
    let textColor: UIColor
    let firstResponderTextColor: UIColor
    let borderColor: UIColor
    let firstResponderBorderColor: UIColor
    let backgroundColor: UIColor
    let firstResponderBackgroundColor: UIColor

    static let `default` = RecipientChipTheme(
        textColor: .tintColor,
        firstResponderTextColor: UserDefaults.shared.accentColor.secondary.color,
        borderColor: UserDefaults.shared.accentColor.secondary.color,
        firstResponderBorderColor: .tintColor,
        backgroundColor: UserDefaults.shared.accentColor.secondary.color,
        firstResponderBackgroundColor: .tintColor
    )

    static let external = RecipientChipTheme(
        textColor: MailResourcesAsset.textPrimaryColor.color,
        firstResponderTextColor: MailResourcesAsset.onTagExternalColor.color,
        borderColor: MailResourcesAsset.yellowColor.color,
        firstResponderBorderColor: MailResourcesAsset.yellowColor.color,
        backgroundColor: MailResourcesAsset.textFieldColor.color,
        firstResponderBackgroundColor: MailResourcesAsset.yellowColor.color
    )

    static let encrypted = RecipientChipTheme(
        textColor: MailResourcesAsset.textSovereignBlueColor.color,
        firstResponderTextColor: MailResourcesAsset.backgroundSovereignBlueColor.color,
        borderColor: MailResourcesAsset.backgroundSovereignBlueColor.color,
        firstResponderBorderColor: MailResourcesAsset.textSovereignBlueColor.color,
        backgroundColor: MailResourcesAsset.backgroundSovereignBlueColor.color,
        firstResponderBackgroundColor: MailResourcesAsset.textSovereignBlueColor.color
    )
}

public enum RecipientChipType: Equatable {
    case `default`
    case external
    case encrypted

    var theme: RecipientChipTheme {
        switch self {
        case .default:
            return .default
        case .external:
            return .external
        case .encrypted:
            return .encrypted
        }
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

    var type: RecipientChipType

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

    public var hasText = false

    private let label: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 1
        label.font = .systemFont(ofSize: 16)
        return label
    }()

    private var accessoryViewConstraints = [NSLayoutConstraint]()

    public init(recipient: Recipient, type: RecipientChipType) {
        self.type = type
        super.init(frame: .zero)

        label.text = recipient.name.isEmpty ? recipient.email : recipient.name

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
        setTheme(type.theme, isFirstResponder: isFirstResponder)
    }

    private func setTheme(_ theme: RecipientChipTheme, isFirstResponder: Bool) {
        label.textColor = isFirstResponder ? theme.firstResponderTextColor : theme.textColor
        borderColor = isFirstResponder ? theme.firstResponderBorderColor : theme.borderColor
        backgroundColor = isFirstResponder ? theme.firstResponderBackgroundColor : theme.backgroundColor
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
        RecipientChipLabelView(recipient: PreviewHelper.sampleRecipient1, type: .default) {} switchFocusHandler: {}

        RecipientChipLabelView(recipient: PreviewHelper.sampleRecipient1, type: .default) {} switchFocusHandler: {} accessory: {
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
