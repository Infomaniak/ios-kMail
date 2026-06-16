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

import DesignSystem
import InfomaniakCoreSwiftUI
import MailCore
import MailCoreUI
import SwiftUI

struct ComposeMessageCellTextField: View {
    @Binding var text: String

    @FocusState var focusedField: ComposeViewFieldType?

    let autocompletionType: ComposeViewFieldType?
    let type: ComposeViewFieldType

    var body: some View {
        if autocompletionType == nil {
            VStack(spacing: 0) {
                HStack(alignment: .top, spacing: IKPadding.mini) {
                    Text(type.title)
                        .textStyle(.bodySecondary)

                    SubjectTextView(text: $text, focusedField: _focusedField)
                        .focused($focusedField, equals: .subject)
                        .accessibilityIdentifier(type.title)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, IKPadding.composeViewHeaderCellLargeVertical)
                .padding(.horizontal, IKPadding.composeViewHeaderHorizontal)

                IKDivider()
            }
            .contentShape(Rectangle())
            .onTapGesture {
                focusedField = type
            }
        }
    }
}

private struct SubjectTextView: UIViewRepresentable {
    @Binding var text: String
    @FocusState var focusedField: ComposeViewFieldType?

    func makeUIView(context: Context) -> UITextView {
        let uiTextView = UITextView()
        uiTextView.delegate = context.coordinator
        uiTextView.isScrollEnabled = false
        uiTextView.backgroundColor = .clear
        uiTextView.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 16))
        uiTextView.textColor = UIColor(MailTextStyle.body.color)
        uiTextView.adjustsFontForContentSizeCategory = true
        uiTextView.textContainerInset = .zero
        uiTextView.textContainer.lineFragmentPadding = 0
        return uiTextView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UITextView, context: Context) -> CGSize? {
        let width = proposal.width ?? uiView.bounds.width
        let size = uiView.sizeThatFits(CGSize(width: width, height: .infinity))
        return CGSize(width: width, height: size.height)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, focusedField: _focusedField)
    }

    class Coordinator: NSObject, UITextViewDelegate {
        @Binding var text: String
        @FocusState var focusedField: ComposeViewFieldType?

        init(text: Binding<String>, focusedField: FocusState<ComposeViewFieldType?>) {
            _text = text
            _focusedField = focusedField
        }

        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            guard text != "\n" else {
                focusedField = .editor
                return false
            }

            if text.contains("\n") {
                let sanitized = text.replacingOccurrences(of: "\n", with: " ")
                let newText = (textView.text as NSString).replacingCharacters(in: range, with: sanitized)
                textView.text = newText
                self.text = newText
                return false
            }
            return true
        }

        func textViewDidChange(_ textView: UITextView) {
            text = textView.text
        }
    }
}

#Preview {
    ComposeMessageCellTextField(text: .constant(""), autocompletionType: nil, type: .subject)
}
