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

import MailCore
import MailResources
import RealmSwift
import SwiftUI

struct AttachmentPreview: View {
    @Binding var isPresented: Bool
    @State var isFullScreen = false
    @ObservedRealmObject var attachment: Attachment

    var body: some View {
        ZStack(alignment: .top) {
            if let url = attachment.localUrl, FileManager.default.fileExists(atPath: url.path) {
                PreviewController(url: url)
            } else {
                ProgressView()
            }

            HStack {
                if !isFullScreen {
                    Button {
                        isPresented = false
                    } label: {
                        Circle()
                            .foregroundColor(Color(MailResourcesAsset.backgroundColor.color).opacity(0.8))
                            .frame(width: 44, height: 44)
                            .overlay(
                                Image(systemName: "chevron.left")
                                    .frame(width: 16, height: 16)
                            )
                            .padding(EdgeInsets(top: 16, leading: 16, bottom: 0, trailing: 16))
                    }
                }
                Spacer()
                Button {
                    isFullScreen.toggle()
                } label: {
                    Circle()
                        .foregroundColor(Color(MailResourcesAsset.backgroundColor.color).opacity(0.8))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Image(systemName: isFullScreen
                                ? "arrow.down.right.and.arrow.up.left"
                                : "arrow.up.left.and.arrow.down.right")
                                .frame(width: 16, height: 16)
                        )
                        .padding(EdgeInsets(top: 16, leading: 16, bottom: 0, trailing: 16))
                }
            }
            if !isFullScreen {
                VStack {
                    Spacer()
                    AttachmentPreviewFooter(attachment: attachment)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .foregroundColor(Color(MailResourcesAsset.backgroundColor.color))
                        )
                }.padding(.bottom, -10)
            }
        }
    }
}

struct AttachmentPreview_Previews: PreviewProvider {
    static var previews: some View {
        AttachmentPreview(isPresented: .constant(true), attachment: PreviewHelper.sampleAttachment)
    }
}
