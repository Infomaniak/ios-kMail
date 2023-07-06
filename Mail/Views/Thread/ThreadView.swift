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
import RealmSwift
import SwiftUI

private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGPoint = .zero

    static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) {
        // No need to implement it
    }
}

struct ThreadView: View {
    @LazyInjectService private var matomo: MatomoUtils

    @Environment(\.isCompactWindow) private var isCompactWindow
    @Environment(\.dismiss) private var dismiss

    @EnvironmentObject private var splitViewManager: SplitViewManager
    @EnvironmentObject private var mailboxManager: MailboxManager
    @EnvironmentObject private var navigationStore: NavigationStore

    @State private var headerHeight: CGFloat = 0
    @State private var displayNavigationTitle = false
    @State private var replyOrReplyAllMessage: Message?

    @ObservedRealmObject var thread: Thread

    private let toolbarActions: [Action] = [.reply, .forward, .archive, .delete]

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                GeometryReader { proxy in
                    Color.clear.preference(
                        key: ScrollOffsetPreferenceKey.self,
                        value: proxy.frame(in: .named("scrollView")).origin
                    )
                }
                .frame(width: 0, height: 0)

                Text(thread.formattedSubject)
                    .textStyle(.header2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(8)
                    .padding(.top, 8)
                    .padding(.bottom, 16)
                    .padding(.horizontal, 16)

                MessageListView(messages: thread.messages)
            }
        }
        .background(MailResourcesAsset.backgroundColor.swiftUIColor)
        .coordinateSpace(name: "scrollView")
        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { offset in
            displayNavigationTitle = offset.y < -85
        }
        .onAppear {
            matomo.track(
                eventWithCategory: .userInfo,
                action: .data,
                name: "nbMessagesInThread",
                value: Float(thread.messages.count)
            )
        }
        .task {
            if thread.hasUnseenMessages {
                try? await mailboxManager.toggleRead(threads: [thread])
            }
        }
        .navigationTitle(displayNavigationTitle ? thread.formattedSubject : "")
        .navigationBarThreadViewStyle(appearance: displayNavigationTitle ? BarAppearanceConstants
            .threadViewNavigationBarScrolledAppearance : BarAppearanceConstants.threadViewNavigationBarAppearance)
        .backButtonDisplayMode(.minimal)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    Task {
                        await tryOrDisplayError {
                            try await mailboxManager.toggleStar(threads: [thread])
                        }
                    }
                } label: {
                    (thread.flagged ? MailResourcesAsset.starFull : MailResourcesAsset.star).swiftUIImage
                        .foregroundColor(thread.flagged ? MailResourcesAsset.yellowColor.swiftUIColor : .accentColor)
                }
            }
        }
        .bottomBar {
            ForEach(toolbarActions) { action in
                if action == .reply {
                    ToolbarButton(text: action.title, icon: action.icon) {
                        didTap(action: action)
                    }
                    .adaptivePanel(item: $replyOrReplyAllMessage) { message in
                        ReplyActionsView(
                            mailboxManager: mailboxManager,
                            message: message,
                            messageReply: $navigationStore.messageReply
                        )
                    }
                } else {
                    ToolbarButton(text: action.title, icon: action.icon) {
                        didTap(action: action)
                    }
                    .disabled(action == .archive && thread.folder?.role == .archive)
                }
                Spacer()
            }
            ActionsPanelButton(threads: [thread]) {
                ToolbarButtonLabel(text: MailResourcesStrings.Localizable.buttonMore,
                                   icon: MailResourcesAsset.plusActions.swiftUIImage)
            }
            .frame(maxWidth: .infinity)
        }
        .onChange(of: thread.messages) { newMessagesList in
            guard isCompactWindow, newMessagesList.isEmpty || thread.messageInFolderCount == 0 else {
                return
            }

            // Dismiss on iPhone only
            dismiss()
        }
        .matomoView(view: [MatomoUtils.View.threadView.displayName, "Main"])
    }

    private func didTap(action: Action) {
        if let matomoName = action.matomoName {
            matomo.track(eventWithCategory: .threadActions, name: matomoName)
        }
        switch action {
        case .reply:
            guard let message = thread.lastMessageToExecuteAction() else { return }
            if message.canReplyAll {
                replyOrReplyAllMessage = message
            } else {
                navigationStore.messageReply = MessageReply(message: message, replyMode: .reply)
            }
        case .forward:
            guard let message = thread.lastMessageToExecuteAction() else { return }
            navigationStore.messageReply = MessageReply(message: message, replyMode: .forward)
        case .archive:
            Task {
                await tryOrDisplayError {
                    let undoRedoAction = try await mailboxManager.move(threads: [thread], to: .archive)
                    IKSnackBar.showCancelableSnackBar(
                        message: MailResourcesStrings.Localizable.snackbarThreadMoved(FolderRole.archive.localizedName),
                        cancelSuccessMessage: MailResourcesStrings.Localizable.snackbarMoveCancelled,
                        undoRedoAction: undoRedoAction,
                        mailboxManager: mailboxManager
                    )
                    dismiss()
                }
            }
        case .delete:
            Task {
                await tryOrDisplayError {
                    try await mailboxManager.moveOrDelete(threads: [thread])
                    dismiss()
                }
            }
        default:
            break
        }
    }
}

struct VerticalLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(spacing: 4) {
            configuration.icon
            configuration.title
        }
    }
}

extension LabelStyle where Self == VerticalLabelStyle {
    static var vertical: VerticalLabelStyle { .init() }
}

extension Label {
    @ViewBuilder
    func dynamicLabelStyle(sizeClass: UserInterfaceSizeClass) -> some View {
        if sizeClass == .compact {
            labelStyle(.iconOnly)
        } else {
            labelStyle(.vertical)
        }
    }
}

struct ThreadView_Previews: PreviewProvider {
    static var previews: some View {
        ThreadView(thread: PreviewHelper.sampleThread)
            .environmentObject(PreviewHelper.sampleMailboxManager)
    }
}
