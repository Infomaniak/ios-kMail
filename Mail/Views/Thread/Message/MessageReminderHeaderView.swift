/*
 Infomaniak Mail - iOS App
 Copyright (C) 2026 Infomaniak Network SA

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

import IKSnackbar
import InfomaniakCoreCommonUI
import InfomaniakDI
import MailCore
import MailCoreUI
import MailResources
import SwiftUI

struct MessageReminderHeaderView: View {
    @LazyInjectService var matomo: MatomoUtils
    @LazyInjectService var snackbarPresenter: IKSnackBarPresentable
    @EnvironmentObject private var mailboxManager: MailboxManager
    @State private var isShowingReschedulePanel = false

    let reminderState: ReminderBannerState
    let message: Message
    let showBottomSeparator: Bool
    let followUpAction: () -> Void

    var body: some View {
        Group {
            switch reminderState {
            case .pastEditable:
                MessageHeaderActionView(
                    icon: MailResourcesAsset.alarmClock.swiftUIImage,
                    message: reminderState.title,
                    showBottomSeparator: showBottomSeparator
                ) {
                    ViewThatFits(in: .horizontal) {
                        HStack {
                            Button(MailResourcesStrings.Localizable.reminderFollowUpButton, action: followUpAction)
                            MessageHeaderDivider()
                            Button(MailResourcesStrings.Localizable.buttonReschedule) {
                                isShowingReschedulePanel = true
                            }
                            MessageHeaderDivider()
                            Button(MailResourcesStrings.Localizable.reminderMarkAsDoneButton, action: markAsDone)
                        }

                        VStack(alignment: .leading) {
                            HStack {
                                Button(MailResourcesStrings.Localizable.reminderFollowUpButton, action: followUpAction)
                                MessageHeaderDivider()
                                Button(MailResourcesStrings.Localizable.buttonReschedule) {
                                    isShowingReschedulePanel = true
                                }
                            }
                            Button(MailResourcesStrings.Localizable.reminderMarkAsDoneButton, action: markAsDone)
                        }
                    }
                }
            case .futureEditable:
                MessageHeaderActionView(
                    icon: MailResourcesAsset.alarmClock.swiftUIImage,
                    message: reminderState.title,
                    showBottomSeparator: showBottomSeparator
                ) {
                    HStack {
                        Button(MailResourcesStrings.Localizable.buttonReschedule) {
                            isShowingReschedulePanel = true
                        }
                        MessageHeaderDivider()
                        Button(MailResourcesStrings.Localizable.buttonCancelReminder, action: removeReminder)
                    }
                }
            case .scheduled:
                MessageHeaderActionView(
                    icon: MailResourcesAsset.alarmClock.swiftUIImage,
                    message: reminderState.title,
                    showBottomSeparator: showBottomSeparator
                ) {
                    HStack {
                        Button(MailResourcesStrings.Localizable.buttonReschedule) {
                            isShowingReschedulePanel = true
                        }
                        MessageHeaderDivider()
                        Button(MailResourcesStrings.Localizable.buttonCancelReminder, action: removeReminder)
                    }
                }
            case .displayOnly:
                MessageHeaderActionView(
                    icon: MailResourcesAsset.alarmClock.swiftUIImage,
                    message: reminderState.title,
                    showBottomSeparator: showBottomSeparator
                ) {}
            }
        }
        .reminderFloatingPanel(
            isPresented: $isShowingReschedulePanel,
            isRescheduling: true
        ) { reminder in
            changeReminderDelta(newReminderOption: reminder)
        }
    }

    private func removeReminder() {
        matomo.track(eventWithCategory: .messageBanner, name: "reminderRemove")
        Task {
            do {
                try await mailboxManager.deleteReminder(message: message)
                snackbarPresenter.show(message: MailResourcesStrings.Localizable.snackbarDisableReminderSuccess)
            } catch {
                snackbarPresenter.show(message: MailResourcesStrings.Localizable.snackbarDisableReminderFailure)
            }
        }
    }

    private func changeReminderDelta(newReminderOption: ReminderOption) {
        matomoForReschedule()
        let delta = newReminderOption.inMinutes
        Task {
            do {
                try await mailboxManager.updateReminder(message: message, reminderDelta: delta)
                snackbarPresenter.show(message: MailResourcesStrings.Localizable.snackbarModifyReminderSuccess)
            } catch {
                snackbarPresenter.show(message: MailResourcesStrings.Localizable.snackbarModifyReminderFailure)
            }
        }
        isShowingReschedulePanel = false
    }

    private func markAsDone() {
        matomo.track(eventWithCategory: .messageBanner, name: "markAsDone")
        Task {
            do {
                try await mailboxManager.markAsDone(message: message)
                snackbarPresenter.show(message: MailResourcesStrings.Localizable.snackbarMarkAsDoneReminderSuccess)
            } catch {
                snackbarPresenter.show(message: MailResourcesStrings.Localizable.snackbarMarkAsDoneReminderFailure)
            }
        }
    }

    private func matomoForReschedule() {
        switch reminderState {
        case .futureEditable:
            matomo.track(eventWithCategory: .messageBanner, name: "rescheduleExpiredReminder")
        default:
            matomo.track(eventWithCategory: .messageBanner, name: "rescheduleActiveReminder")
        }
    }
}

#Preview {
    MessageReminderHeaderView(reminderState: .scheduled(deltaMinutes: 60), message: PreviewHelper.sampleMessage,
                              showBottomSeparator: true) {}
        .environmentObject(PreviewHelper.sampleMailboxManager)
        .environmentObject(MainViewState(
            mailboxManager: PreviewHelper.sampleMailboxManager,
            selectedFolder: PreviewHelper.sampleFolder
        ))
}
