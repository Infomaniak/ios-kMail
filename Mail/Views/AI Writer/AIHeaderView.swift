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

struct AIHeaderView: View {
    enum Style {
        case bottomSheet, sheet
    }

    let style: Style

    var body: some View {
        HStack(spacing: UIPadding.small) {
            if style == .bottomSheet {
                MailResourcesAsset.aiWriter.swiftUIImage
                    .resizable()
                    .frame(width: 16, height: 16)
                    .foregroundColor(MailResourcesAsset.aiColor)
            }

            Text(MailResourcesStrings.Localizable.aiPromptTitle)
                .font(style == .bottomSheet ? MailTextStyle.header2.font : .headline)
                .foregroundColor(MailTextStyle.header2.color)

            Text(MailResourcesStrings.Localizable.aiPromptTag)
                .tagModifier(foregroundColor: MailResourcesAsset.onAIColor, backgroundColor: MailResourcesAsset.aiColor)
        }
        .onAppear {
            dump(Font.headline)
        }
    }
}

struct AIHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        AIHeaderView(style: .bottomSheet)
    }
}
