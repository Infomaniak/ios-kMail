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

import InfomaniakCore
import InfomaniakCoreCommonUI
import InfomaniakDI
import MailCore
import MailCoreUI
import MailResources
import SwiftUI

struct ReportJunkView: View {
    @InjectService private var platformDetector: PlatformDetectable

    @EnvironmentObject private var mailboxManager: MailboxManager
    @Environment(\.dismiss) private var dismiss

    let reportedMessages: [Message]
    let origin: ActionOrigin
    var completionHandler: ((Action) -> Void)?

    private var filteredActions: [Action] {
        let currentUserEmail = mailboxManager.mailbox.email
        let uniqueSenders = Set(reportedMessages.compactMap { $0.from.first?.email })

        if uniqueSenders == [currentUserEmail] {
            return [.spam, .phishing]
        } else {
            return [.spam, .phishing, .blockList]
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if platformDetector.isMac {
                HeaderCloseButtonView(title: MailResourcesStrings.Localizable.actionReportJunk) {
                    dismiss()
                }
                .padding(.horizontal, value: .medium)
            }

            ForEach(filteredActions) { action in
                if action != filteredActions.first {
                    IKDivider()
                }
                MessageActionView(
                    targetMessages: reportedMessages,
                    action: action,
                    origin: origin,
                    isMultipleSelection: false,
                    completionHandler: completionHandler
                )
            }
        }
        .matomoView(view: [MatomoUtils.View.bottomSheet.displayName, "ReportJunkView"])
    }
}

#Preview {
    ReportJunkView(
        reportedMessages: PreviewHelper.sampleMessages,
        origin: .floatingPanel(source: .threadList)
    ) { _ in }
        .accentColor(AccentColor.pink.primary.swiftUIColor)
        .environmentObject(PreviewHelper.sampleMailboxManager)
}
