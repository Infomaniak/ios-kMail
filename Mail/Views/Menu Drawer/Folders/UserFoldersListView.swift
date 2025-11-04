/*
 Infomaniak Mail - iOS App
 Copyright (C) 2024 Infomaniak Network SA

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
import InfomaniakCore
import InfomaniakCoreCommonUI
import InfomaniakCoreSwiftUI
import InfomaniakDI
import MailCore
import MailCoreUI
import MailResources
import RealmSwift
import SwiftModalPresentation
import SwiftUI
import UIKit

struct UserFoldersListView: View {
    @State private var isExpanded = true
    @ModalState private var isShowingCreateFolderAlert = false

    let folders: [NestableFolder]

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: IKPadding.menuDrawerCellChevronSpacing) {
                Button {
                    withAnimation {
                        isExpanded.toggle()
                        @InjectService var matomo: MatomoUtils
                        matomo.track(eventWithCategory: .menuDrawer, name: "customFolders", value: isExpanded)
                    }
                } label: {
                    HStack(spacing: IKPadding.menuDrawerCellChevronSpacing) {
                        ChevronIcon(direction: isExpanded ? .up : .down)
                        Text(MailResourcesStrings.Localizable.buttonFolders)
                            .textStyle(.bodySmallSecondary)
                        Spacer()
                    }
                    .padding(value: .medium)
                }
                .frame(maxWidth: .infinity)
                .accessibilityLabel(MailResourcesStrings.Localizable.contentDescriptionButtonExpandCustomFolders)

                Button {
                    @InjectService var matomo: MatomoUtils
                    matomo.track(eventWithCategory: .createFolder, name: "fromMenuDrawer")
                    isShowingCreateFolderAlert.toggle()
                } label: {
                    MailResourcesAsset.addCircle
                        .iconSize(.medium)
                        .padding(value: .medium)
                }
                .accessibilityLabel(MailResourcesStrings.Localizable.newFolderDialogTitle)
                .mailCustomAlert(isPresented: $isShowingCreateFolderAlert) {
                    CreateFolderView(mode: .create)
                }
            }

            if isExpanded {
                if folders.isEmpty {
                    Text(MailResourcesStrings.Localizable.noFolderTitle)
                        .textStyle(.bodySmallSecondary)
                        .padding(value: .medium)
                } else {
                    FoldersListView(folders: folders)
                }
            }
        }
    }
}

#Preview {
    UserFoldersListView(folders: [NestableFolder(content: PreviewHelper.sampleFolder, children: [])])
        .environmentObject(MainViewState(
            mailboxManager: PreviewHelper.sampleMailboxManager,
            selectedFolder: PreviewHelper.sampleFolder
        ))
        .environment(\.currentUser, MandatoryEnvironmentContainer(value: PreviewHelper.sampleUser))
}
