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

import InfomaniakCoreUI
import InfomaniakDI
import MailCore
import MailCoreUI
import MailResources
import SwiftModalPresentation
import SwiftUI

struct ExternalTagBottomView: View {
    @LazyInjectService private var matomo: MatomoUtils

    @ModalState(context: ContextKeys.externalTagBottom) private var isShowingExternalTagAlert = false
    @State private var isShowingExternalTag = true

    let externalTag: DisplayExternalRecipientStatus.State

    var body: some View {
        if isShowingExternalTag && externalTag.shouldDisplay {
            HStack(spacing: UIPadding.small) {
                Button {
                    matomo.track(eventWithCategory: .externals, name: "bannerInfo")
                    isShowingExternalTagAlert = true
                } label: {
                    HStack(spacing: UIPadding.small) {
                        Text(MailResourcesStrings.Localizable.externalDialogTitleRecipient)
                            .font(MailTextStyle.bodySmallMedium.font)

                        IKIcon(MailResourcesAsset.info)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .customAlert(isPresented: $isShowingExternalTagAlert) {
                    ExternalRecipientView(externalTagSate: externalTag, isDraft: true)
                }

                Button {
                    matomo.track(eventWithCategory: .externals, name: "bannerManuallyClosed")
                    isShowingExternalTag = false
                } label: {
                    IKIcon(MailResourcesAsset.close)
                }
            }
            .padding(value: .regular)
            .foregroundStyle(MailResourcesAsset.onTagExternalColor)
            .background(MailResourcesAsset.yellowColor.swiftUIColor)
        }
    }
}

#Preview {
    ExternalTagBottomView(externalTag: .many)
}
