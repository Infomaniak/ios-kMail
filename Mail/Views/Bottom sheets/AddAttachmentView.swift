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

import MailResources
import PhotosUI
import SwiftUI

class NewMessageAttachmentSheet: SheetState<NewMessageAttachmentSheet.State> {
    enum State {
        case fileSelection, photoLibrary, camera
    }
}

enum AttachmentResult {
    case files([URL])
    case photos([PHPickerResult])
    case camera(Data)
}

struct AddAttachmentView: View {
    @ObservedObject var bottomSheet: NewMessageBottomSheet
    let didSelectAttachment: (AttachmentResult) -> Void

    @StateObject private var attachmentSheet = NewMessageAttachmentSheet()
    @State private var isPresenting = false

    private struct AttachmentAction: Hashable {
        let name: String
        let image: UIImage

        static let addFile = AttachmentAction(
            name: MailResourcesStrings.Localizable.attachmentActionFile,
            image: MailResourcesAsset.folder.image
        )
        static let addPhotoFromLibrary = AttachmentAction(
            name: MailResourcesStrings.Localizable.attachmentActionPhotoLibrary,
            image: MailResourcesAsset.pictureLandscape.image
        )
        static let openCamera = AttachmentAction(
            name: MailResourcesStrings.Localizable.attachmentActionCamera,
            image: MailResourcesAsset.photo.image
        )
    }

    private let actions: [AttachmentAction] = [
        .addFile, .addPhotoFromLibrary, .openCamera
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(MailResourcesStrings.Localizable.attachmentActionTitle)
                .textStyle(.header3)
                .padding([.leading, .trailing], 16)

            ForEach(actions, id: \.self) { action in
                Button {
                    if action == .addFile {
                        attachmentSheet.state = .fileSelection
                    }
                    if action == .addPhotoFromLibrary {
                        attachmentSheet.state = .photoLibrary
                    }
                    if action == .openCamera {
                        attachmentSheet.state = .camera
                    }
                } label: {
                    HStack {
                        Image(uiImage: action.image)
                        Text(action.name)
                            .textStyle(.body)
                    }
                }
                .frame(height: 40)
                .padding(.horizontal, 24)

                if action != .openCamera {
                    IKDivider()
                        .padding(.horizontal, 8)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 16)
        .sheet(isPresented: $attachmentSheet.isShowing) {
            switch attachmentSheet.state {
            case .fileSelection:
                DocumentPicker { urls in
                    didSelectAttachment(.files(urls))
                    bottomSheet.close()
                }
            case .photoLibrary:
                ImagePicker { results in
                    didSelectAttachment(.photos(results))
                }
            case .camera:
                CameraPicker { data in
                    didSelectAttachment(.camera(data))
                }
            case .none:
                EmptyView()
            }
        }
    }
}

struct AddAttachmentView_Previews: PreviewProvider {
    static var previews: some View {
        AddAttachmentView(bottomSheet: NewMessageBottomSheet()) { _ in /* Preview */ }
    }
}
