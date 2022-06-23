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
import SwiftUI

struct AttachmentView: View {
    @ObservedObject var bottomSheet: NewMessageBottomSheet

    private struct AttachmentAction: Hashable {
        let name: String
        let image: UIImage

        static let addFile = AttachmentAction(
            name: "Joindre un fichier",
            image: MailResourcesAsset.folder.image
        )
        static let addPhotoFromLibrary = AttachmentAction(
            name: "Envoyer une photo depuis la phototèque",
            image: MailResourcesAsset.photo.image
        )
        static let openCamera = AttachmentAction(
            name: "Appareil Photo",
            image: MailResourcesAsset.photo.image
        )
    }

    private let actions: [AttachmentAction] = [
        .addFile, .addPhotoFromLibrary, .openCamera
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Ajouter une pièce jointe")
                .textStyle(.header3)

            ForEach(actions, id: \.self) { action in
                Button {
                    handleAction(action)
                } label: {
                    HStack {
                        Image(uiImage: action.image)
                        Text(action.name)
                            .textStyle(.body)
                    }
                }
                .frame(height: 40)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding([.leading, .trailing], 24)
        .padding(.top, 16)
    }

    private func handleAction(_ action: AttachmentAction) {
        switch action {
        case .addFile:
            // TODO: handle action
            break
        case .addPhotoFromLibrary:
            // TODO: handle action
            break
        case .openCamera:
            // TODO: handle action
            break
        default:
            return
        }
    }
}

struct AttachmentView_Previews: PreviewProvider {
    static var previews: some View {
        AttachmentView(bottomSheet: NewMessageBottomSheet())
    }
}
