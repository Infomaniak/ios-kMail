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
        case fileSelection, photoLibrary
    }
}

enum AttachmentResult {
    case files([URL])
    case photos([PHPickerResult])
}

struct AddAttachmentView: View {
    @ObservedObject var bottomSheet: NewMessageBottomSheet
    let didSelectAttachment: (AttachmentResult) -> Void

    @StateObject private var attachmentSheet = NewMessageAttachmentSheet()
    @State private var isPresenting = false

    private struct AttachmentAction: Identifiable, Equatable {
        static func == (lhs: AddAttachmentView.AttachmentAction, rhs: AddAttachmentView.AttachmentAction) -> Bool {
            return lhs.id == rhs.id
        }

        let id: Int
        let name: String
        let image: MailResourcesImages

        static let addFile = AttachmentAction(
            id: 1,
            name: MailResourcesStrings.Localizable.attachmentActionFile,
            image: MailResourcesAsset.folder
        )
        static let addPhotoFromLibrary = AttachmentAction(
            id: 2,
            name: MailResourcesStrings.Localizable.attachmentActionPhotoLibrary,
            image: MailResourcesAsset.pictureLandscape
        )
    }

    private let actions: [AttachmentAction] = [
        .addFile, .addPhotoFromLibrary
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(MailResourcesStrings.Localizable.attachmentActionTitle)
                .textStyle(.header3)
                .padding(.horizontal, 16)
                .padding(.bottom, 32)

            ForEach(actions) { action in
                Button {
                    switch action {
                    case .addFile:
                        attachmentSheet.state = .fileSelection
                    case .addPhotoFromLibrary:
                        attachmentSheet.state = .photoLibrary
                    default:
                        break
                    }
                } label: {
                    HStack(spacing: 16) {
                        Image(resource: action.image)
                        Text(action.name)
                            .textStyle(.body)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 32)

                if action != actions.last {
                    IKDivider()
                        .padding(.horizontal, 8)
                        .padding(.vertical, 16)
                }
            }
        }
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
