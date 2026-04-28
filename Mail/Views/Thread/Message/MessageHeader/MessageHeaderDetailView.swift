/*
 Infomaniak Mail - iOS App
 Copyright (C) 2022 Infomaniak Network SA

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
import SwiftUI

struct MessageHeaderDetailView: View {
    @ObservedRealmObject var message: Message

    var body: some View {
        Grid(alignment: .leading, horizontalSpacing: IKPadding.mini, verticalSpacing: IKPadding.mini) {
            RecipientRow(
                title: MailResourcesStrings.Localizable.fromTitle,
                recipients: message.from,
                bimi: message.bimi
            )
            RecipientRow(title: MailResourcesStrings.Localizable.toTitle, recipients: message.to)
            if !message.cc.isEmpty {
                RecipientRow(title: MailResourcesStrings.Localizable.ccTitle, recipients: message.cc)
            }
            if !message.bcc.isEmpty {
                RecipientRow(title: MailResourcesStrings.Localizable.bccTitle, recipients: message.bcc)
            }

            GridRow {
                MailResourcesAsset.calendar
                    .iconSize(.medium)
                Text(message.date.formatted(date: .long, time: .shortened))
            }
            .textStyle(.bodySmallSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    MessageHeaderDetailView(message: PreviewHelper.sampleMessage)
}
