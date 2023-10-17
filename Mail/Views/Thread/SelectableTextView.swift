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
import MailResources
import SwiftUI
import UIKit

struct SelectableTextView: UIViewRepresentable {
    enum Style {
        case loading, standard, error(withLoadingState: Bool)

        var foregroundColor: UIColor {
            switch self {
            case .loading:
                return MailResourcesAsset.textTertiaryColor.color
            case .standard:
                return MailResourcesAsset.textPrimaryColor.color
            case .error(withLoadingState: let withLoadingState):
                return withLoadingState ? Style.loading.foregroundColor : Style.standard.foregroundColor
            }
        }
    }

    @Binding var textPlainHeight: CGFloat

    let text: String?
    var style = Style.standard

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.dataDetectorTypes = .all
        textView.isScrollEnabled = false
        textView.isEditable = false
        textView.textContainer.lineFragmentPadding = 0
        textView.font = .systemFont(ofSize: 16)
        textView.textColor = style.foregroundColor
        textView.linkTextAttributes = [.underlineStyle: 1, .foregroundColor: UIColor.tintColor]
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textView.backgroundColor = .clear

        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        // Replace text when the style is standard and the current color has not yet been changed
        if case .standard = style, uiView.textColor != style.foregroundColor {
            replaceText(text: text ?? "", in: uiView)
        } else {
            insertText(text: text ?? "", in: uiView)
        }
    }

    private func insertText(text: String, in uiView: UITextView) {
        uiView.text = text
        uiView.textColor = style.foregroundColor

        computeViewHeight(uiView)
    }

    private func replaceText(text: String, in uiView: UITextView) {
        UIView.animate(withDuration: 0.2) {
            uiView.alpha = 0
        } completion: { _ in
            insertText(text: text, in: uiView)
            UIView.animate(withDuration: 0.2) {
                uiView.alpha = 1
            }
        }
    }

    private func computeViewHeight(_ uiView: UIView) {
        Task {
            await MainActor.run {
                let sizeThatFits = uiView.sizeThatFits(CGSize(
                    width: uiView.frame.width,
                    height: CGFloat.greatestFiniteMagnitude
                ))
                textPlainHeight = sizeThatFits.height
            }
        }
    }
}
