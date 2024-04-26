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

import PhotosUI
import SwiftUI
import UIKit

public struct CameraPicker: UIViewControllerRepresentable {
    @Environment(\.presentationMode) private var presentationMode

    let sourceType: UIImagePickerController.SourceType
    let completion: (Data) -> Void

    public init(sourceType: UIImagePickerController.SourceType = .camera, completion: @escaping (Data) -> Void) {
        self.sourceType = sourceType
        self.completion = completion
    }

    public func makeUIViewController(context: Context) -> UIImagePickerController {
        let imagePicker = UIImagePickerController()
        imagePicker.allowsEditing = false
        imagePicker.sourceType = sourceType
        imagePicker.delegate = context.coordinator

        return imagePicker
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    public func updateUIViewController(
        _ uiViewController: CameraPicker.UIViewControllerType,
        context: UIViewControllerRepresentableContext<CameraPicker>
    ) {
        // Empty on prupose
    }

    public final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        var parent: CameraPicker

        init(_ parent: CameraPicker) {
            self.parent = parent
        }

        public func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage,
               let data = image.jpegData(compressionQuality: 0.5) {
                parent.completion(data)
            }

            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
