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

struct NewEditorMobileToolbarView: View {
    @State private var isShowingFormattingOptions = false

    private let actions: [EditorToolbarAction] = [
        .editText, .ai, .addAttachment
    ]

    private let formattingOptions: [EditorToolbarAction] = [
        .bold, .italic, .underline, .strikeThrough, .link, .unorderedList
    ]

    var body: some View {
        HStack {
            if isShowingFormattingOptions {
                Text("Format")
            } else {
                ForEach(actions) { action in
                    Button {
                        performToolbarAction(action)
                    } label: {
                        Label {
                            Text(action.accessibilityLabel)
                        } icon: {
                            action.icon.swiftUIImage
                                .resizable()
                                .iconSize(.large)
                        }
                        .labelStyle(.iconOnly)
                    }

                }
            }
        }
    }

    private func performToolbarAction(_ action: EditorToolbarAction) {
        switch action {
        case .link:
            break
        case .bold:
            break
        case .underline:
            break
        case .italic:
            break
        case .strikeThrough:
            break
        case .cancelFormat:
            break
        case .unorderedList:
            break
        case .editText:
            break
        case .ai:
            break
        case .addAttachment:
            break
        case .addFile:
            break
        case .addPhoto:
            break
        case .takePhoto:
            break
        }
    }
}

#Preview {
    NewEditorMobileToolbarView()
}
