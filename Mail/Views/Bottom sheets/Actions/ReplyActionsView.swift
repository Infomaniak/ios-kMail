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
import MailCore
import MailCoreUI
import SwiftUI

struct ReplyActionsView: View {
    let quickActions: [Action] = [.reply, .replyAll]
    let message: Message

    var body: some View {
        HStack(alignment: .top, spacing: IKPadding.medium) {
            ForEach(quickActions) { action in
                QuickActionView(
                    targetMessages: [message],
                    action: action,
                    origin: .floatingPanel(source: .messageList),
                    isMultipleSelection: false
                )
            }

            Spacer()
        }
        .padding(.horizontal, value: .large)
        .matomoView(view: [MatomoUtils.View.bottomSheet.displayName, "ReplyActionsView"])
    }
}

#Preview {
    ReplyActionsView(message: PreviewHelper.sampleMessage)
        .accentColor(AccentColor.pink.primary.swiftUIColor)
}
