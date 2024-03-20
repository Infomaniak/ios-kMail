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

struct MailRichEditorView: UIViewRepresentable {
    func makeUIView(context: Context) -> some UIView {
        let editor = RichEditorView()
        editor.delegate = context.coordinator
        editor.addInputAccessoryView(context.coordinator.toolbar)

        return editor
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {}

    func makeCoordinator() -> MailRichEditorCoordinator {
        return MailRichEditorCoordinator()
    }
}

#Preview {
    MailRichEditorView()
}
