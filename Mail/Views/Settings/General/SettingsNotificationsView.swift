/*
 Infomaniak Mail - iOS App
 Copyright (C) 2023 Infomaniak Network SA

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

import DesignSystem
import InfomaniakCore
import InfomaniakCoreCommonUI
import InfomaniakCoreSwiftUI
import InfomaniakDI
import InfomaniakNotifications
import MailCore
import MailCoreUI
import MailResources
import SwiftModalPresentation
import SwiftUI

struct SettingsNotificationsView: View {
    @LazyInjectService private var notificationService: InfomaniakNotifications

    @Environment(\.currentUser) private var currentUser

    @EnvironmentObject private var mailboxManager: MailboxManager

    @AppStorage(UserDefaults.shared.key(.notificationsEnabled)) private var notificationsEnabled = DefaultPreferences
        .notificationsEnabled
    @State private var subscribedTopics: [Topic]?

    @ModalState(context: ContextKeys.settings) private var showAlertNotification = false
    @State private var showWarning = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            List {
                if showWarning {
                    VStack(alignment: .leading, spacing: IKPadding.mini) {
                        Text(MailResourcesStrings.Localizable.warningNotificationsDisabledDescription)
                            .textStyle(.bodySecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Button(MailResourcesStrings.Localizable.warningNotificationsDisabledButton) {
                            DeeplinkConstants.presentsNotificationSettings()
                        }
                        .buttonStyle(.ikBorderless(isInlined: true))
                    }
                    .padding(value: .medium)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(MailResourcesAsset.backgroundBlueNavBarColor.swiftUIColor)
                    )
                    .settingsItem()
                    .settingsCell()
                }

                SettingsSectionTitleView(title: Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as! String)
                    .settingsCell()

                SettingsToggleCell(
                    title: MailResourcesStrings.Localizable.settingsEnableNotifications,
                    userDefaults: \.isNotificationEnabled,
                    matomoCategory: .settingsNotifications,
                    matomoName: "allNotifications"
                )
                .settingsCell()

                if subscribedTopics != nil && notificationsEnabled {
                    IKDivider()
                        .settingsCell()

                    ForEachMailboxView(userId: currentUser.value.id) { mailbox in
                        Toggle(isOn: Binding(get: {
                            notificationsEnabled && subscribedTopics?.contains(mailbox.notificationTopicName) == true
                        }, set: { on in
                            @InjectService var matomo: MatomoUtils
                            matomo.track(eventWithCategory: .settingsNotifications, name: "mailboxNotifications", value: on)
                            if on && subscribedTopics?.contains(mailbox.notificationTopicName) == false {
                                subscribedTopics?.append(mailbox.notificationTopicName)
                            } else {
                                subscribedTopics?.removeAll { $0 == mailbox.notificationTopicName }
                            }
                        })) {
                            Text(mailbox.email)
                                .textStyle(.body)
                        }
                        .tint(.accentColor)
                    }
                    .settingsItem()
                    .settingsCell()
                }
            }
            .environment(\.defaultMinListRowHeight, 1)
            .listStyle(.plain)
        }
        .backButtonDisplayMode(.minimal)
        .background(MailResourcesAsset.backgroundColor.swiftUIColor)
        .navigationBarTitle(MailResourcesStrings.Localizable.settingsMailboxGeneralNotifications, displayMode: .inline)
        .onChange(of: notificationsEnabled) { enabled in
            if !enabled {
                subscribedTopics = []
            } else {
                if showWarning {
                    notificationsEnabled = false
                    showAlertNotification = true
                }
            }
        }
        // swiftlint:disable:next trailing_closure
        .sceneLifecycle(willEnterForeground: {
            settingsNotificationEnabled { enabled in
                showWarning = !enabled
            }
        })
        .onAppear {
            settingsNotificationEnabled { enabled in
                showWarning = !enabled
            }
        }
        .task {
            await currentTopics()
        }
        .onDisappear {
            updateTopicsForCurrentUserIfNeeded()
        }
        .mailCustomAlert(isPresented: $showAlertNotification) {
            SettingsNotificationsInstructionsView()
        }
        .matomoView(view: [MatomoUtils.View.settingsView.displayName, "Notifications"])
    }

    private func currentTopics() async {
        let currentSubscription = await notificationService.subscriptionForUser(id: mailboxManager.mailbox.userId)
        withAnimation {
            subscribedTopics = currentSubscription?.topics
        }
    }

    private func updateTopicsForCurrentUserIfNeeded() {
        Task {
            guard let subscribedTopics else { return }

            await notificationService.updateTopicsWithTwoFAIfNeeded(subscribedTopics, userApiFetcher: mailboxManager.apiFetcher)
        }
    }

    private func settingsNotificationEnabled(completion: @escaping ((Bool) -> Void)) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .notDetermined, .denied:
                completion(false)
            default:
                completion(true)
            }
        }
    }
}

#Preview {
    SettingsNotificationsView()
        .environmentObject(PreviewHelper.sampleMailboxManager)
        .environment(\.currentUser, MandatoryEnvironmentContainer(value: PreviewHelper.sampleUser))
}
