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

import SwiftUI
import UIKit

struct RecipientsTextField: UIViewRepresentable {
    @Binding var text: String

    var onSubmit: (() -> Void)?
    let onBackspace: (Bool) -> Void

    func makeUIView(context: Context) -> UITextField {
        let textField = UIRecipientsTextField()
        textField.delegate = context.coordinator
        textField.addTarget(context.coordinator, action: #selector(context.coordinator.textDidChanged(_:)), for: .editingChanged)
        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textField.setContentHuggingPriority(.defaultHigh, for: .vertical)
        textField.onBackspace = onBackspace
        return textField
    }

    func updateUIView(_ textField: UITextField, context: Context) {
        guard textField.text != text else { return }
        textField.text = text
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    class Coordinator: NSObject, UITextFieldDelegate {
        let parent: RecipientsTextField

        init(_ parent: RecipientsTextField) {
            self.parent = parent
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            guard textField.text?.isEmpty == false else {
                textField.resignFirstResponder()
                return true
            }

            parent.onSubmit?()
            return true
        }

        @objc func textDidChanged(_ textField: UITextField) {
            parent.text = textField.text ?? ""
        }
    }
}

/*
 * We need to create our own UITextField to benefit from the `deleteBackward()` function
 */
class UIRecipientsTextField: UITextField {
    var onBackspace: ((Bool) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setUpView()
    }

    private func setUpView() {
        textContentType = .emailAddress
        keyboardType = .emailAddress
        autocapitalizationType = .none
        autocorrectionType = .no
    }

    override func deleteBackward() {
        onBackspace?(text?.isEmpty == true)
        super.deleteBackward()
    }
}

