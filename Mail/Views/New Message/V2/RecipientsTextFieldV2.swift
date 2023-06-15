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

struct RecipientsTextFieldV2View: UIViewRepresentable {
    @Binding var text: String

    var onSubmit: (() -> Void)?
    let onBackspace: (Bool) -> Void

    func makeUIView(context: Context) -> UITextField {
        let textField = RecipientsTextField()
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
        let parent: RecipientsTextFieldV2View

        init(_ parent: RecipientsTextFieldV2View) {
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
