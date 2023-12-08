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

struct MessageHeaderFolderView: View {
    @EnvironmentObject private var mainViewState: MainViewState

    @ObservedRealmObject var message: Message

    private var showFolder: Bool {
        return mainViewState.selectedFolder.remoteId != message.folderId
    }

    var body: some View {
        if showFolder, let folder = message.folder {
            HStack {
                Text(folder.localizedName)
                    .textStyle(.bodySmallSecondary)
                Spacer()
                folder.icon
                    .resizable()
                    .foregroundStyle(MailResourcesAsset.grayActionColor.swiftUIColor)
                    .frame(width: 16, height: 16)
            }
            .padding(.vertical, UIPadding.verySmall)
            .padding(.horizontal, UIPadding.regular)
            .background(MailResourcesAsset.textFieldColor.swiftUIColor)
            .padding(.horizontal, -UIPadding.regular)
            .padding(.top, -UIPadding.regular)
        }
    }
}

#Preview {
    MessageHeaderFolderView(message: PreviewHelper.sampleMessage)
}
