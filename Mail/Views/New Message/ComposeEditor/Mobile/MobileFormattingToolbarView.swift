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

import InfomaniakRichHTMLEditor
import MailCoreUI
import SwiftModalPresentation
import SwiftUI

struct MobileFormattingToolbarView: View {
    @ModalState(context: ContextKeys.compose) private var isShowingLinkAlert = false

    @ObservedObject var textAttributes: TextAttributes

    @Binding var isShowingFormattingOptions: Bool

    private let actions: [EditorToolbarAction] = [
        .bold, .italic, .underline, .strikeThrough, .unorderedList, .link
    ]

    var body: some View {
        HStack {
            Button("close") {
                isShowingFormattingOptions = false
            }

            ForEach(actions) { action in
                MobileToolbarButton(toolbarAction: action) {
                    formatText(for: action)
                }
                .mailCustomAlert(isPresented: $isShowingLinkAlert) {
                    AddLinkView(actionHandler: textAttributes.addLink)
                }
            }
        }
    }

    private func formatText(for action: EditorToolbarAction) {
        switch action {
        case .bold:
            textAttributes.bold()
        case .underline:
            textAttributes.underline()
        case .italic:
            textAttributes.italic()
        case .strikeThrough:
            textAttributes.strikethrough()
        case .cancelFormat:
            textAttributes.removeFormat()
        case .unorderedList:
            textAttributes.unorderedList()
        case .link:
            if textAttributes.hasLink {
                textAttributes.unlink()
            } else {
                isShowingLinkAlert = true
            }
        default:
            return
        }
    }
}

#Preview {
    MobileFormattingToolbarView(textAttributes: TextAttributes(), isShowingFormattingOptions: .constant(false))
}
