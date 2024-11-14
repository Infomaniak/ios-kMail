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

import InfomaniakCore
import InfomaniakDI
import SwiftUI
import UIKit
import UniformTypeIdentifiers

public struct DocumentPicker: UIViewControllerRepresentable {
    public enum PickerType {
        case selectContent([UTType], ([URL]) -> Void)
        case exportContent([URL])
    }

    @Environment(\.dismiss) private var dismiss

    let pickerType: PickerType

    private var shouldCopyDocuments: Bool {
        @InjectService var platformDetector: PlatformDetectable
        return !platformDetector.isMacCatalyst
    }

    public init(pickerType: PickerType) {
        self.pickerType = pickerType
    }

    public func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }

    public func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker: UIDocumentPickerViewController
        switch pickerType {
        case .selectContent(let types, _):
            picker = UIDocumentPickerViewController(forOpeningContentTypes: types, asCopy: shouldCopyDocuments)
            picker.allowsMultipleSelection = true
        case .exportContent(let urls):
            picker = UIDocumentPickerViewController(forExporting: urls, asCopy: true)
        }

        picker.delegate = context.coordinator
        return picker
    }

    public func updateUIViewController(
        _ uiViewController: DocumentPicker.UIViewControllerType,
        context: UIViewControllerRepresentableContext<DocumentPicker>
    ) {
        // Empty on purpose
    }

    public class Coordinator: NSObject, UIDocumentPickerDelegate {
        var parent: DocumentPicker

        init(parent: DocumentPicker) {
            self.parent = parent
        }

        public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            if case .selectContent(_, let completion) = parent.pickerType {
                completion(urls)
            }
            parent.dismiss()
        }
    }
}
