/*
 Infomaniak Mail - iOS App
 Copyright (C) 2024 Infomaniak Network SA

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

import InfomaniakRichEditor
import MailCore
import SwiftUI

struct EditorModel {
    var height: CGFloat = .zero
    var cursorPosition: CGRect? = .zero
}

struct EditorView: UIViewRepresentable {
    @Binding var body: String

    @Binding var model: EditorModel
    @ObservedObject var toolbarModel: EditorToolbarModel

    func makeUIView(context: Context) -> RichEditorView {
        let editor = RichEditorView()
        editor.delegate = context.coordinator
        editor.isScrollable = false
        editor.inputAccessoryView = context.coordinator.toolbar

        editor.html = body
        let editorCSS = MessageWebViewUtils.loadCSS(for: .editor)
        for css in editorCSS {
            editor.injectAdditionalCSS(css)
        }

        return editor
    }

    func updateUIView(_ richEditorView: RichEditorView, context: Context) {
        if richEditorView.html != body {
            richEditorView.html = body
        }
    }

    func makeCoordinator() -> EditorCoordinator {
        return EditorCoordinator(parent: self)
    }
}

#Preview {
    EditorView(body: .constant(""), model: .constant(EditorModel()), toolbarModel: EditorToolbarModel())
}
