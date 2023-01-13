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

import InfomaniakCore
import MailCore
import MailResources
import RealmSwift
import SwiftUI
import UIKit

struct UserFoldersListView: View {
    var folders: [NestableFolder]

    @State private var isExpanded = true

    @EnvironmentObject var globalAlert: GlobalAlert

    var isCompact: Bool

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 12) {
                    ChevronIcon(style: isExpanded ? .up : .down, color: .secondary)
                    Text(MailResourcesStrings.Localizable.buttonFolders)
                        .textStyle(.bodySmallSecondary)
                    Spacer()
                    Button {
                        globalAlert.state = .createNewFolder(mode: .create)
                    } label: {
                        Image(resource: MailResourcesAsset.addCircle)
                            .resizable()
                            .frame(width: 16, height: 16)
                    }
                }
            }
            .padding(.leading, Constants.menuDrawerHorizontalPadding)
            .padding(.trailing, 18)

            if isExpanded {
                Spacer(minLength: Constants.menuDrawerVerticalPadding)

                if folders.isEmpty {
                    Text(MailResourcesStrings.Localizable.noFolderTitle)
                        .textStyle(.bodySmallSecondary)
                        .padding(.top, 16)
                        .padding(.bottom, 8)
                } else {
                    ForEach(folders) { folder in
                        FolderCell(folder: folder, isCompact: isCompact)
                    }
                }
            }
        }
        .padding(.top, 16)
        .padding(.bottom, 12)
    }
}
