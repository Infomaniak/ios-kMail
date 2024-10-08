/*
 Infomaniak Mail - iOS App
 Copyright (C) 2024 Infomaniak Network SA

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

import Combine
import InfomaniakCoreCommonUI
import InfomaniakDI
import InfomaniakRichHTMLEditor
import MailCore
import SwiftUI
import UIKit

final class EditorToolbarView: UIToolbar {
    private static let flexibleSpaceItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)

    @LazyInjectService private var matomo: MatomoUtils

    private var type = EditorToolbarStyle.main

    private var textAttributes: TextAttributes?
    private var textAttributesObservation: AnyCancellable?

    var mainButtonItemsHandler: ((EditorToolbarAction) -> Void)?

    init() {
        super.init(frame: CGRect(x: 0, y: 0, width: 0, height: 48))

        UIConstants.applyComposeViewStyle(to: self)
        setupType(.main)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setTextAttributes(_ textAttributes: TextAttributes) {
        self.textAttributes = textAttributes
        textAttributesObservation = textAttributes
            .objectWillChange
            .debounce(for: .milliseconds(50), scheduler: DispatchQueue.main)
            .sink { [weak self] in
                guard let self else { return }
                setupType(type)
            }
    }

    private func setupType(_ type: EditorToolbarStyle) {
        self.type = type

        let actions = type.actions
        let actionItems = actions.map { action in
            let actionImage = action.icon.image.resize(size: CGSize(width: 24, height: 24))
            let item = UIBarButtonItem(
                image: actionImage,
                style: .plain,
                target: self,
                action: #selector(didTapOnBarButtonItem)
            )
            item.tag = action.rawValue
            item.accessibilityLabel = action.accessibilityLabel
            if let textAttributes {
                item.isSelected = action.isSelected(textAttributes: textAttributes)
            }
            if action == .editText && type == .textEdition {
                item.tintColor = UserDefaults.shared.accentColor.primary.color
            } else {
                item.tintColor = action.tint
            }

            return item
        }

        let barButtonItems = Array(actionItems.map { [$0] }.joined(separator: [Self.flexibleSpaceItem]))
        setItems(barButtonItems, animated: false)
        setNeedsLayout()
    }

    @objc private func didTapOnBarButtonItem(_ sender: UIBarButtonItem) {
        guard let action = EditorToolbarAction(rawValue: sender.tag) else {
            return
        }

        if let matomoName = action.matomoName {
            matomo.track(eventWithCategory: .editorActions, name: matomoName)
        }

        switch action {
        case .editText:
            setupType(type == .main ? .textEdition : .main)
        case .bold:
            textAttributes?.bold()
        case .italic:
            textAttributes?.italic()
        case .underline:
            textAttributes?.underline()
        case .strikeThrough:
            textAttributes?.strikethrough()
        case .unorderedList:
            textAttributes?.unorderedList()
        case .link:
            guard let textAttributes else { return }
            if textAttributes.hasLink {
                textAttributes.unlink()
            } else {
                mainButtonItemsHandler?(action)
            }
        case .ai, .addFile, .addPhoto, .takePhoto, .programMessage, .cancelFormat:
            mainButtonItemsHandler?(action)
        }
    }
}
