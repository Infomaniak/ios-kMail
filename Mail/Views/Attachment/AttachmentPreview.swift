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
    @ObservedRealmObject var attachment: Attachment

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.black.ignoresSafeArea()
            VStack {
                if let url = attachment.localUrl {
                    if FileManager.default.fileExists(atPath: url.path) {
                        PreviewController(url: url)
                    }
                } else {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                AttachmentPreviewFooter(attachment: attachment)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .foregroundColor(Color(MailResourcesAsset.backgroundColor.color))
                            .edgesIgnoringSafeArea(.bottom)
                    )
            }
            Circle()
                .foregroundColor(Color(MailResourcesAsset.backgroundColor.color).opacity(0.8))
                .frame(width: 44, height: 44)
                .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                .overlay(
                    Button {
                        isPresented = false
                    } label: {
                        Image(systemName: "chevron.left")
                            .frame(width: 16, height: 16)
                    }
                )
                .padding(EdgeInsets(top: 16, leading: 16, bottom: 0, trailing: 16))
        }
    }
}

struct AttachmentPreview_Previews: PreviewProvider {
    static var previews: some View {
        AttachmentPreview(isPresented: .constant(true), attachment: PreviewHelper.sampleAttachment)
    }
}
