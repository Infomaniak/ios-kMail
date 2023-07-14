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
import UniformTypeIdentifiers

struct DocumentPicker: UIViewControllerRepresentable {
    enum PickerType {
        case selectContent([UTType], ([URL]) -> Void)
        case exportContent([URL])
    }

    @Environment(\.dismiss) private var dismiss

    let pickerType: PickerType

    func makeCoordinator() -> DocumentPicker.Coordinator {
        return DocumentPicker.Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker: UIDocumentPickerViewController
        switch pickerType {
        case .selectContent(let types, _):
            picker = UIDocumentPickerViewController(forOpeningContentTypes: types, asCopy: true)
            picker.allowsMultipleSelection = true
        case .exportContent(let urls):
            picker = UIDocumentPickerViewController(forExporting: urls, asCopy: true)
        }

        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(
        _ uiViewController: DocumentPicker.UIViewControllerType,
        context: UIViewControllerRepresentableContext<DocumentPicker>
    ) {
        // Empty on purpose
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        var parent: DocumentPicker

        init(parent: DocumentPicker) {
            self.parent = parent
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            if case .selectContent(_, let completion) = parent.pickerType {
                completion(urls)
            }
            parent.dismiss()
        }
    }
}
