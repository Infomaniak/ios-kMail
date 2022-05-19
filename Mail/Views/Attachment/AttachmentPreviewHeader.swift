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
import MailResources

struct AttachmentPreviewHeader: View {
    @Binding var isPresented: Bool
    @Binding var isFullScreen: Bool
    
    var body: some View {
        HStack {
            if !isFullScreen {
                Button {
                    isPresented = false
                } label: {
                    Circle()
                        .foregroundColor(Color(MailResourcesAsset.backgroundColor.color).opacity(0.8))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Image(resource: MailResourcesAsset.arrowLeft)
                                .foregroundColor(.black)
                                .frame(width: 16, height: 16)
                        )
                }
                .transition(.move(edge: .top))
            }
            Spacer()
            Button {
                withAnimation {
                    isFullScreen.toggle()
                }
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
            }
        }
        .padding([.top, .leading, .trailing], 16)
    }
}

struct AttachmentPreviewHeader_Previews: PreviewProvider {
    static var previews: some View {
        AttachmentPreviewHeader(isPresented: .constant(true), isFullScreen: .constant(false))
    }
}
