/*
 Infomaniak Mail - iOS App
 Copyright (C) 2024 Infomaniak Network SA

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
import InfomaniakCoreUI
import InfomaniakDI
import MailCore
import MailCoreUI
import MailResources
import SwiftUI

struct UpdateVersionView: View {
    @LazyInjectService private var matomo: MatomoUtils

    @Binding var isShowingUpdateAlert: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .iconAndMultilineTextAlignment, spacing: UIPadding.small) {
                IKIcon(MailResourcesAsset.warning)
                    .foregroundStyle(MailResourcesAsset.orangeColor)
                    .alignmentGuide(.iconAndMultilineTextAlignment) { d in
                        d[VerticalAlignment.center]
                    }

                Text(MailResourcesStrings.Localizable.updateVersionTitle)
                    .textStyle(.bodySmall)
                    .alignmentGuide(.iconAndMultilineTextAlignment) { d in
                        (d.height - (d[.lastTextBaseline] - d[.firstTextBaseline])) / 2
                    }
            }
            .padding(.top, value: .regular)
            .padding(.horizontal, value: .regular)
            .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                matomo.track(eventWithCategory: .updateVersion, name: "moreInfo")
                isShowingUpdateAlert = true
            } label: {
                Text(MailResourcesStrings.Localizable.moreInfo)
                    .textStyle(.bodySmallAccent)
            }
            .buttonStyle(.ikLink())
            .padding(.leading, value: .regular)

            IKDivider(type: .full)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    UpdateVersionView(isShowingUpdateAlert: .constant(true))
}
