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

struct ActionsView: View {
    @ObservedObject var viewModel: ActionsViewModel

    init(mailboxManager: MailboxManager,
         target: ActionsTarget,
         state: ThreadBottomSheet,
         globalSheet: GlobalBottomSheet,
         replyHandler: @escaping (Message, ReplyMode) -> Void) {
        viewModel = ActionsViewModel(mailboxManager: mailboxManager,
                                     target: target,
                                     state: state,
                                     globalSheet: globalSheet,
                                     replyHandler: replyHandler)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            Text(MailResourcesStrings.Localizable.actionsMenuTitle)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textStyle(.header3)
                .padding([.leading, .trailing], 24)
            // Quick actions
            HStack(alignment: .top, spacing: 28) {
                ForEach(viewModel.quickActions) { action in
                    QuickActionView(viewModel: viewModel, action: action)
                }
                .fixedSize(horizontal: false, vertical: true)
            }
            .padding([.leading, .trailing], 24)
            .padding(.bottom, 16)
            // Actions
            ForEach(viewModel.listActions) { action in
                IKDivider()
                ActionView(viewModel: viewModel, action: action)
                    .padding([.leading, .trailing], 24)
            }
        }
        .padding([.leading, .trailing], 8)
        .padding(.top, 16)
    }
}

struct ActionsView_Previews: PreviewProvider {
    static var previews: some View {
        ActionsView(mailboxManager: PreviewHelper.sampleMailboxManager,
                    target: .thread(PreviewHelper.sampleThread),
                    state: ThreadBottomSheet(),
                    globalSheet: GlobalBottomSheet()) { _, _ in }
            .accentColor(AccentColor.pink.primary.swiftUiColor)
    }
}

struct QuickActionView: View {
    @ObservedObject var viewModel: ActionsViewModel
    let action: Action

    @AppStorage(UserDefaults.shared.key(.accentColor)) private var accentColor = AccentColor.pink

    var body: some View {
        Button {
            Task {
                await tryOrDisplayError {
                    try await viewModel.didTap(action: action)
                }
            }
        } label: {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(accentColor.secondary.swiftUiColor)

                    Image(resource: action.icon)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(19)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .aspectRatio(1, contentMode: .fit)

                Text(action.title)
                    .font(.system(size: 12))
            }
        }
    }
}

struct ActionView: View {
    @ObservedObject var viewModel: ActionsViewModel
    let action: Action

    var body: some View {
        Button {
            Task {
                await tryOrDisplayError {
                    try await viewModel.didTap(action: action)
                }
            }
        } label: {
            HStack(spacing: 20) {
                Image(resource: action.icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 21, height: 21)
                Text(action.title)
                    .textStyle(.body)
            }
        }
    }
}
