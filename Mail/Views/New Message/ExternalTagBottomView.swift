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
import MailCoreUI
import MailResources
import SwiftModalPresentation
import SwiftUI

struct ExternalTagBottomView: View {
    @ModalState(context: ContextKeys.externalTagBottom) private var isShowingExternalTagAlert = false
    @State private var isShowingExternalTag = true

    let externalTag: DisplayExternalRecipientStatus.State

    var body: some View {
        if isShowingExternalTag && externalTag.shouldDisplay {
            HStack(spacing: IKPadding.mini) {
                Button {
                    track(eventName: "bannerInfo")
                    isShowingExternalTagAlert = true
                } label: {
                    HStack(spacing: IKPadding.mini) {
                        Text(MailResourcesStrings.Localizable.externalDialogTitleRecipient)
                            .font(MailTextStyle.bodySmallMedium.font)

                        MailResourcesAsset.info
                            .iconSize(.medium)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .mailCustomAlert(isPresented: $isShowingExternalTagAlert) {
                    ExternalRecipientView(externalTagSate: externalTag, isDraft: true)
                }

                Button {
                    track(eventName: "bannerManuallyClosed")
                    isShowingExternalTag = false
                } label: {
                    MailResourcesAsset.close
                        .iconSize(.medium)
                }
            }
            .padding(value: .medium)
            .foregroundStyle(MailResourcesAsset.onTagExternalColor)
            .background(MailResourcesAsset.yellowColor.swiftUIColor)
        }
    }

    private func track(eventName: String) {
        @InjectService var matomo: MatomoUtils
        matomo.track(eventWithCategory: .externals, name: eventName)
    }
}

#Preview {
    ExternalTagBottomView(externalTag: .many)
}
