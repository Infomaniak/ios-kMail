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
import InfomaniakCoreUI
import MailCore
import SwiftUI

struct ReportJunkView: View {
    let reportedMessage: Message
    let actions: [Action] = [.spam, .phishing, .block]
    let origin: ActionOrigin

    var body: some View {
        VStack(alignment: .leading, spacing: UIConstants.actionsViewSpacing) {
            ForEach(actions) { action in
                if action != actions.first {
                    IKDivider()
                }

                MessageActionView(targetMessages: [reportedMessage], action: action, origin: origin)
                    .padding(.horizontal, UIConstants.actionsViewCellHorizontalPadding)
            }
        }
        .padding(.horizontal, UIConstants.actionsViewHorizontalPadding)
        .matomoView(view: [MatomoUtils.View.bottomSheet.displayName, "ReportJunkView"])
    }
}

struct ReportJunkView_Previews: PreviewProvider {
    static var previews: some View {
        ReportJunkView(reportedMessage: PreviewHelper.sampleMessage, origin: .floatingPanel())
            .accentColor(AccentColor.pink.primary.swiftUIColor)
    }
}
