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
import SwiftUI

struct reportOptionsView: View {
    @ObservedObject var viewModel: ActionsViewModel

    var actions: [Action] = []

    init(mailboxManager: MailboxManager,
         target: ActionsTarget,
         state: ThreadBottomSheet,
         globalSheet: GlobalBottomSheet) {
        viewModel = ActionsViewModel(mailboxManager: mailboxManager,
                                     target: target,
                                     state: state,
                                     globalSheet: globalSheet)
        switch target {
        case let .message(message):
            let spam = message.folderId == mailboxManager.getFolder(with: .spam)?._id
            actions.append(contentsOf: [
                spam ? .nonSpam : .spam,
                .block,
                .phishing
            ])
        default:
            break
        }
    }

    var body: some View {
        ForEach(actions) { action in
            if action != viewModel.listActions.first {
                IKDivider()
            }
            ActionView(viewModel: viewModel, action: action)
                .padding(.horizontal, 24)
        }
    }
}

struct reportOptionsView_Previews: PreviewProvider {
    static var previews: some View {
        reportOptionsView(mailboxManager: PreviewHelper.sampleMailboxManager,
                          target: .threads([PreviewHelper.sampleThread]),
                          state: ThreadBottomSheet(),
                          globalSheet: GlobalBottomSheet())
            .accentColor(AccentColor.pink.primary.swiftUiColor)
    }
}
