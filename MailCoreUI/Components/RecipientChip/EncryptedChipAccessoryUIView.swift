/*
 Infomaniak Mail - iOS App
 Copyright (C) 2025 Infomaniak Network SA

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

import MailResources
import SwiftUI
import UIKit

final class EncryptedChipAccessoryUIView: UIView {
    var isEncrypted: Bool {
        didSet {
            setEncryptState()
        }
    }

    private let badgeWidth: CGFloat = 8.0
    private let iconSize = CGSize(width: 16, height: 16)

    override var intrinsicContentSize: CGSize {
        return iconSize
    }

    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private lazy var badgeView: UIView = {
        let view = UIView()
        view.backgroundColor = MailResourcesAsset.orangeColor.color
        view.layer.cornerRadius = badgeWidth / 2
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    init(isEncrypted: Bool) {
        self.isEncrypted = isEncrypted
        super.init(frame: .zero)
        setupView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setFocused(_ focused: Bool) {
        overrideUserInterfaceStyle = focused ? .dark : .light
    }

    private func setupView() {
        addSubview(imageView)
        addSubview(badgeView)

        setEncryptState()

        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            imageView.widthAnchor.constraint(equalToConstant: iconSize.width),
            imageView.heightAnchor.constraint(equalToConstant: iconSize.height),

            badgeView.widthAnchor.constraint(equalToConstant: badgeWidth),
            badgeView.heightAnchor.constraint(equalToConstant: badgeWidth),
            badgeView.topAnchor.constraint(equalTo: topAnchor),
            badgeView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 2),

            widthAnchor.constraint(equalToConstant: iconSize.width),
            heightAnchor.constraint(equalToConstant: iconSize.height)
        ])
    }

    private func setEncryptState() {
        if isEncrypted {
            imageView.image = MailResourcesAsset.lockSquareFill.image
            imageView.tintColor = MailResourcesAsset.iconSovereignBlueColor.color
        } else {
            imageView.image = MailResourcesAsset.unlockSquareFill.image
            imageView.tintColor = MailResourcesAsset.textSecondaryColor.color
        }

        badgeView.isHidden = isEncrypted
    }
}

struct EncryptedChipAccessoryView: UIViewRepresentable {
    let isEncrypted: Bool

    func makeUIView(context: Context) -> EncryptedChipAccessoryUIView {
        let view = EncryptedChipAccessoryUIView(isEncrypted: isEncrypted)
        view.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        view.setContentHuggingPriority(.defaultHigh, for: .vertical)
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return view
    }

    func updateUIView(_ uiView: EncryptedChipAccessoryUIView, context: Context) {
        uiView.isEncrypted = isEncrypted
    }
}

@available(iOS 17.0, *)
#Preview {
    EncryptedChipAccessoryUIView(isEncrypted: false)
}

@available(iOS 17.0, *)
#Preview {
    EncryptedChipAccessoryUIView(isEncrypted: true)
}
