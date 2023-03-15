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

struct ReplyActionsView: View {
    @ObservedObject var viewModel: ActionsViewModel

    var quickActions: [Action] = [.reply, .replyAll]

    init(mailboxManager: MailboxManager,
         target: ActionsTarget,
         state: ThreadBottomSheet,
         globalSheet: GlobalBottomSheet,
         replyHandler: @escaping (Message, ReplyMode) -> Void) {
        viewModel = ActionsViewModel(mailboxManager: mailboxManager,
                                     target: target,
                                     state: state,
                                     globalSheet: globalSheet,
                                     matomoCategory: .replyBottomSheet,
                                     replyHandler: replyHandler)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 28) {
            ForEach(quickActions) { action in
                QuickActionView(viewModel: viewModel, action: action)
                    .frame(width: 70)
            }

            Spacer()
        }
        .padding(.horizontal, 24)
        .matomoView(view: [MatomoUtils.View.bottomSheet.displayName, "ReplyActionsView"])
    }
}

struct ReplyActionsView_Previews: PreviewProvider {
    static var previews: some View {
        ReplyActionsView(mailboxManager: PreviewHelper.sampleMailboxManager,
                         target: .threads([PreviewHelper.sampleThread], false),
                         state: ThreadBottomSheet(),
                         globalSheet: GlobalBottomSheet()) { _, _ in /* Preview */ }
            .accentColor(AccentColor.pink.primary.swiftUiColor)
    }
}
