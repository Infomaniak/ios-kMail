//
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
import SwiftUI

struct AttachmentPreviewFooter: View {
    var attachment: Attachment
    @State private var isSharePresented = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(attachment.name)
            HStack {
                Text("75 Mo")
                Text("•")
                Text("Modifié le 27 Aout 2020 - 16:10")
            }
            .font(.system(size: 16, weight: .regular))
            .foregroundColor(Color(MailResourcesAsset.secondaryTextColor.color))

            HStack {
                Button {
                    isSharePresented = true
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                            .frame(width: 24, height: 24)
                        Text("Partager")
                            .fontWeight(.semibold)
                    }
                }
                Spacer()
                Button {
                    downloadAttachment()
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                            .frame(width: 24, height: 24)
                        Text("Télécharger")
                            .fontWeight(.semibold)
                    }
                }
            }
            .padding(.top, 22)
        }
        .background(Color(MailResourcesAsset.backgroundColor.color))
        .padding(32)
        .sheet(isPresented: $isSharePresented) {
            if let itemUrl = attachment.localUrl {
                ActivityViewController(activityItems: [itemUrl])
            }
        }
    }

    private func downloadAttachment() {}
}

struct AttachmentPreviewFooter_Previews: PreviewProvider {
    static var previews: some View {
        AttachmentPreviewFooter(attachment: PreviewHelper.sampleAttachment)
    }
}
