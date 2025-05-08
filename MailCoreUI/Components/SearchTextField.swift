/*
 Infomaniak Mail - iOS App
 Copyright (C) 2022 Infomaniak Network SA

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
import InfomaniakCoreSwiftUI
import MailCore
import MailResources
import SwiftUI

// This is hack because we can't use introspect because of a bug and we also can't use standard focus modifier in a toolbar
private struct TextFieldFocuserView: UIViewRepresentable {
    private static let maxSearchDepth = 10

    private class TextFieldFinderUIView: UIView {
        weak var textField: UITextField?
        var initialFocusDone = false

        override func didMoveToWindow() {
            super.didMoveToWindow()

            guard !initialFocusDone else {
                return
            }

            guard let textField else {
                findTextField(view: self)
                textField?.becomeFirstResponder()
                initialFocusDone = true
                return
            }

            textField.becomeFirstResponder()
            initialFocusDone = true
        }

        private func findTextField(view: UIView, level: Int = 0) {
            if let textField = view as? UITextField {
                self.textField = textField
                return
            }

            guard level < TextFieldFocuserView.maxSearchDepth else {
                return
            }

            for subview in view.subviews {
                findTextField(view: subview, level: level + 1)
            }

            if let superview = view.superview {
                findTextField(view: superview, level: level + 1)
            }
        }
    }

    func makeUIView(context: Context) -> UIView {
        return TextFieldFinderUIView()
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

public struct SearchTextField: View {
    @EnvironmentObject private var mainViewState: MainViewState

    @Binding var value: String

    let onSubmit: () -> Void
    let onDelete: () -> Void

    public init(value: Binding<String>, onSubmit: @escaping () -> Void, onDelete: @escaping () -> Void) {
        _value = value
        self.onSubmit = onSubmit
        self.onDelete = onDelete
    }

    public var body: some View {
        HStack(spacing: IKPadding.mini) {
            Button(action: onSubmit) {
                MailResourcesAsset.search
                    .iconSize(.medium)
                    .foregroundStyle(MailResourcesAsset.textTertiaryColor)
            }
            TextField(MailResourcesStrings.Localizable.searchFieldPlaceholder, text: $value)
                .overlay {
                    TextFieldFocuserView()
                        .frame(width: 0, height: 0)
                        .accessibility(hidden: true)
                }
                .autocorrectionDisabled()
                .submitLabel(.search)
                .foregroundStyle(value.isEmpty
                    ? MailResourcesAsset.textTertiaryColor
                    : MailResourcesAsset.textPrimaryColor)
                .onSubmit {
                    onSubmit()
                }
                .accessibilityAction(.escape) {
                    mainViewState.isShowingSearch = false
                }
                .padding(.vertical, value: .small)

            Button(action: onDelete) {
                MailResourcesAsset.remove
                    .iconSize(.medium)
                    .foregroundStyle(MailResourcesAsset.textTertiaryColor)
            }
            .opacity(value.isEmpty ? 0 : 1)
        }
        .padding(.horizontal, value: .small)
        .background {
            RoundedRectangle(cornerRadius: 27)
                .foregroundStyle(MailResourcesAsset.textFieldColor)
        }
    }
}

#Preview {
    SearchTextField(
        value: .constant("Recherche"),
        onSubmit: { /* Empty on purpose */ },
        onDelete: { /* Empty on purpose */ }
    )
}
