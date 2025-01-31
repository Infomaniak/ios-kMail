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
import InfomaniakCoreCommonUI
import InfomaniakCoreSwiftUI
import InfomaniakDI
import MailCore
import MailResources
import SwiftModalPresentation
import SwiftUI
import WrappingHStack

struct ThreadTagsListView: View {
    @LazyInjectService private var matomo: MatomoUtils

    @ModalState private var isShowingExternalTagAlert = false

    let externalTag: DisplayExternalRecipientStatus.State
    let searchFolderName: String?

    var body: some View {
        WrappingHStack(lineSpacing: IKPadding.mini) {
            if externalTag.shouldDisplay {
                Button {
                    matomo.track(eventWithCategory: .externals, name: "threadTag")
                    isShowingExternalTagAlert = true
                } label: {
                    Text(MailResourcesStrings.Localizable.externalTag)
                        .tagModifier(
                            foregroundColor: MailResourcesAsset.onTagExternalColor,
                            backgroundColor: MailResourcesAsset.yellowColor
                        )
                }
                .customAlert(isPresented: $isShowingExternalTagAlert) {
                    ExternalRecipientView(externalTagSate: externalTag, isDraft: false)
                }
            }

            MessageFolderTag(title: searchFolderName, inThreadHeader: true)
        }
    }
}

#Preview {
    ThreadTagsListView(externalTag: .many, searchFolderName: "Hello")
}
