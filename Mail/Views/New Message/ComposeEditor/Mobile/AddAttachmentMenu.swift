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

import DesignSystem
import InfomaniakCoreSwiftUI
import InfomaniakCoreUIResources
import MailCore
import MailCoreUI
import PhotosUI
import SwiftModalPresentation
import SwiftUI

struct AddAttachmentMenu: View {
    @EnvironmentObject private var attachmentsManager: AttachmentsManager

    @ModalState(context: ContextKeys.compose) private var isShowingFileSelection = false
    @ModalState(context: ContextKeys.compose) private var isShowingPhotoLibrary = false
    @ModalState(context: ContextKeys.compose) private var isShowingCamera = false

    @State private var selectedImage: UIImage?

    let draft: Draft

    private let action = EditorToolbarAction.addAttachment

    var body: some View {
        Menu {
            Button {
                isShowingCamera = true
            } label: {
                Label(CoreUILocalizable.buttonUploadFromCamera, asset: EditorToolbarAction.takePhoto.icon.swiftUIImage)
            }
            Button {
                isShowingPhotoLibrary = true
            } label: {
                Label(CoreUILocalizable.buttonUploadFromGallery, asset: EditorToolbarAction.addPhoto.icon.swiftUIImage)
            }
            Button {
                isShowingFileSelection = true
            } label: {
                Label(CoreUILocalizable.buttonUploadFromFiles, asset: EditorToolbarAction.addFile.icon.swiftUIImage)
            }
        } label: {
            Label {
                Text(action.accessibilityLabel)
            } icon: {
                action.icon.swiftUIImage
                    .iconSize(MobileToolbarButtonStyle.iconSize)
            }
            .labelStyle(.iconOnly)
        }
        .buttonStyle(.mobileToolbar(isActivated: false))
        .onChange(of: selectedImage) { newImage in
            guard let image = newImage,
                  let data = image.jpegData(compressionQuality: 0.5) else {
                return
            }
            didTakePhoto(data)
            selectedImage = nil
        }
        .sheet(isPresented: $isShowingFileSelection) {
            DocumentPicker(pickerType: .selectContent([.item], didPickDocument))
                .ignoresSafeArea()
        }
        .sheet(isPresented: $isShowingPhotoLibrary) {
            ImagePicker(completion: didPickImage)
                .ignoresSafeArea()
        }
        .fullScreenCover(isPresented: $isShowingCamera) {
            CameraPickerView(selectedImage: $selectedImage)
                .ignoresSafeArea()
        }
    }

    private func didPickDocument(_ urls: [URL]) {
        attachmentsManager.importAttachments(
            attachments: urls,
            draft: draft,
            disposition: AttachmentDisposition.defaultDisposition
        )
    }

    private func didPickImage(_ results: [PHPickerResult]) {
        attachmentsManager.importAttachments(
            attachments: results,
            draft: draft,
            disposition: AttachmentDisposition.defaultDisposition
        )
    }

    private func didTakePhoto(_ data: Data) {
        attachmentsManager.importAttachments(
            attachments: [data],
            draft: draft,
            disposition: AttachmentDisposition.defaultDisposition
        )
    }
}
