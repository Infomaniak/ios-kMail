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
import MailResources
import SwiftUI

struct ActionsView: View {
    @ObservedObject var viewModel: ActionsViewModel

    init(mailboxManager: MailboxManager,
         target: ActionsTarget,
         moveSheet: MoveSheet? = nil,
         messageReply: Binding<MessageReply?>? = nil,
         reportJunkActionsTarget: Binding<ActionsTarget?>? = nil,
         reportedForDisplayProblemMessage: Binding<Message?>? = nil,
         completionHandler: (() -> Void)? = nil) {
        var matomoCategory = MatomoUtils.EventCategory.bottomSheetMessageActions
        if case .threads = target {
            matomoCategory = .bottomSheetThreadActions
        }

        viewModel = ActionsViewModel(mailboxManager: mailboxManager,
                                     target: target,
                                     moveSheet: moveSheet,
                                     messageReply: messageReply,
                                     reportJunkActionsTarget: reportJunkActionsTarget,
                                     reportedForDisplayProblemMessage: reportedForDisplayProblemMessage,
                                     matomoCategory: matomoCategory,
                                     completionHandler: completionHandler)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Quick actions
            HStack(alignment: .top, spacing: 16) {
                ForEach(viewModel.quickActions) { action in
                    QuickActionView(viewModel: viewModel, action: action)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.bottom, 16)
            .padding(.horizontal, 16)
            // Actions
            ForEach(viewModel.listActions) { action in
                if action != viewModel.listActions.first {
                    IKDivider()
                }
                ActionView(viewModel: viewModel, action: action)
                    .padding(.horizontal, 24)
            }
        }
        .padding(.horizontal, 8)
        .matomoView(view: [MatomoUtils.View.bottomSheet.displayName, "ActionsView"])
    }
}

struct ActionsView_Previews: PreviewProvider {
    static var previews: some View {
        ActionsView(mailboxManager: PreviewHelper.sampleMailboxManager, target: .threads([PreviewHelper.sampleThread], false))
            .accentColor(AccentColor.pink.primary.swiftUIColor)
    }
}

struct QuickActionView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: ActionsViewModel
    let action: Action

    @AppStorage(UserDefaults.shared.key(.accentColor)) private var accentColor = DefaultPreferences.accentColor

    var body: some View {
        Button {
            dismiss()
            Task {
                await tryOrDisplayError {
                    try await viewModel.didTap(action: action)
                }
            }
        } label: {
            VStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(accentColor.secondary.swiftUIColor)
                    .frame(maxWidth: 56, maxHeight: 56)
                    .aspectRatio(1, contentMode: .fit)
                    .overlay {
                        action.icon
                            .resizable()
                            .scaledToFit()
                            .padding(16)
                    }
                    .padding(.horizontal, 8)

                let title = action.shortTitle ?? action.title
                Text(title)
                    .textStyle(.labelMediumAccent)
                    .lineLimit(title.split(separator: " ").count > 1 ? nil : 1)
            }
        }
    }
}

struct ActionView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: ActionsViewModel
    let action: Action

    @AppStorage(UserDefaults.shared.key(.accentColor)) private var accentColor = DefaultPreferences.accentColor

    var body: some View {
        Button {
            dismiss()
            Task {
                await tryOrDisplayError {
                    try await viewModel.didTap(action: action)
                }
            }
        } label: {
            HStack(spacing: 20) {
                action.icon
                    .resizable()
                    .scaledToFit()
                    .frame(width: 21, height: 21)
                    .foregroundColor(action == .report ? MailResourcesAsset.princeColor : accentColor.primary)
                Text(action.title)
                    .foregroundColor(action == .report ? MailResourcesAsset.princeColor : MailResourcesAsset.textPrimaryColor)
                    .textStyle(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}
