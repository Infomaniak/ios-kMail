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
import MailCore
import SwiftUI

struct ReportJunkView: View {
    @ObservedObject var viewModel: ActionsViewModel

    var actions: [Action] = []

    init(mailboxManager: MailboxManager,
         target: ActionsTarget,
         state: ThreadBottomSheet,
         globalSheet: GlobalBottomSheet,
         globalAlert: GlobalAlert) {
        viewModel = ActionsViewModel(mailboxManager: mailboxManager,
                                     target: target,
                                     state: state,
                                     globalSheet: globalSheet,
                                     globalAlert: globalAlert)
        if case let .message(message) = target {
            let spam = message.folder?.role == .spam
            actions.append(contentsOf: [
                spam ? .nonSpam : .spam,
                .phishing,
                .block
            ])
        }
    }

    var body: some View {
        Group {
            ForEach(actions) { action in
                if action != actions.first {
                    IKDivider()
                }
                ActionView(viewModel: viewModel, action: action)
                    .padding(.horizontal, 24)
            }
        }
        .matomoView(view: [MatomoUtils.View.bottomSheet.displayName, "ReportJunkView"])
    }
}

struct ReportJunkView_Previews: PreviewProvider {
    static var previews: some View {
        ReportJunkView(mailboxManager: PreviewHelper.sampleMailboxManager,
                       target: .threads([PreviewHelper.sampleThread], false),
                       state: ThreadBottomSheet(),
                       globalSheet: GlobalBottomSheet(),
                       globalAlert: GlobalAlert())
            .accentColor(AccentColor.pink.primary.swiftUiColor)
    }
}
