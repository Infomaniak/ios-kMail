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
import InfomaniakDI
import MailCore
import MailResources
import SwiftUI

struct ReportJunkView: View {
    @LazyInjectService private var platformDetector: PlatformDetectable

    @Environment(\.dismiss) private var dismiss

    let reportedMessage: Message
    let actions: [Action] = [.spam, .phishing, .block]
    let origin: ActionOrigin

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if platformDetector.isMac {
                HeaderCloseButtonView(title: MailResourcesStrings.Localizable.actionReportJunk) {
                    dismiss()
                }
                .padding(.horizontal, value: .regular)
            }

            ForEach(actions) { action in
                if action != actions.first {
                    IKDivider()
                }

                MessageActionView(targetMessages: [reportedMessage], action: action, origin: origin)
            }
        }
        .matomoView(view: [MatomoUtils.View.bottomSheet.displayName, "ReportJunkView"])
    }
}

#Preview {
    ReportJunkView(reportedMessage: PreviewHelper.sampleMessage, origin: .floatingPanel(source: .threadList))
        .accentColor(AccentColor.pink.primary.swiftUIColor)
}
