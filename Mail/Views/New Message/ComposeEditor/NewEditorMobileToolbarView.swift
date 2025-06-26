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

import SwiftUI

struct MobileToolbarButton: View {
    let text: String
    let icon: Image
    let action: @MainActor () -> Void

    init(toolbarAction: EditorToolbarAction, perform actionToPerform: @escaping @MainActor () -> Void) {
        text = toolbarAction.accessibilityLabel
        icon = toolbarAction.icon.swiftUIImage
        action = actionToPerform
    }

    var body: some View {
        Button(action: action) {
            Label {
                Text(text)
            } icon: {
                icon
                    .resizable()
                    .iconSize(.large)
            }
            .labelStyle(.iconOnly)
        }
    }
}

struct AddAttachmentMenu: View {
    var body: some View {

    }
}

struct NewEditorMobileToolbarView: View {
    @State private var isShowingFormattingOptions = false
    @State private var isShowingAttachmentMenu = false

    private let mainActions: [EditorToolbarAction] = [
        .editText, .ai, .addAttachment
    ]

    private let formattingOptions: [EditorToolbarAction] = [
        .bold, .italic, .underline, .strikeThrough, .link, .unorderedList
    ]

    private var currentActions: [EditorToolbarAction] {
        if isShowingFormattingOptions {
            return formattingOptions
        } else {
            return mainActions
        }
    }

    var body: some View {
        HStack {
            if isShowingFormattingOptions {
                Button("close") {
                    isShowingFormattingOptions = false
                }

                ForEach(formattingOptions) { action in
                    MobileToolbarButton(toolbarAction: action) {
                        performToolbarAction(action)
                    }
                }
            } else {
                ForEach(currentActions) { action in
                    switch action {
                    case .addAttachment:
                        AddAttachmentMenu()
                    default:
                        MobileToolbarButton(toolbarAction: action) {
                            performToolbarAction(action)
                        }
                        .tint(Color(action.tint))
                    }
                }
            }
        }
        .animation(.default, value: isShowingFormattingOptions)
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    private func performToolbarAction(_ action: EditorToolbarAction) {
        switch action {
        case .editText:
            isShowingFormattingOptions = true
        case .addAttachment:
            isShowingAttachmentMenu = true
        default:
            print("Coucou")
        }
    }
}

#Preview {
    NewEditorMobileToolbarView()
}
