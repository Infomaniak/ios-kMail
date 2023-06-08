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
import InfomaniakNotifications
import MailCore
import MailResources
import SwiftUI

struct SettingsNotificationsView: View {
    @LazyInjectService private var notificationService: InfomaniakNotifications
    @LazyInjectService private var matomo: MatomoUtils

    @AppStorage(UserDefaults.shared.key(.notificationsEnabled)) private var notificationsEnabled = DefaultPreferences
        .notificationsEnabled
    @State var subscribedTopics: [String]?

    @State private var showAlertNotification = false
    @State private var showWarning = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if showWarning {
                    HStack {
                        VStack(spacing: 8) {
                            Text(MailResourcesStrings.Localizable.warningNotificationsDisabledDescription)
                                .textStyle(.bodySecondary)
                            MailButton(label: MailResourcesStrings.Localizable.warningNotificationsDisabledButton) {
                                guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                                    return
                                }

                                if UIApplication.shared.canOpenURL(settingsUrl) {
                                    UIApplication.shared.open(settingsUrl)
                                }
                            }
                            .mailButtonStyle(.link)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(MailResourcesAsset.backgroundBlueNavBarColor.swiftUIColor)
                        )
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                }

                Text(Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as! String)
                    .textStyle(.bodySmallSecondary)

                Toggle(isOn: $notificationsEnabled) {
                    Text(MailResourcesStrings.Localizable.settingsEnableNotifications)
                        .textStyle(.body)
                }
                .onChange(of: notificationsEnabled) { newValue in
                    matomo.track(eventWithCategory: .settingsNotifications, name: "allNotifications", value: newValue)
                }

                if subscribedTopics != nil && notificationsEnabled {
                    IKDivider()
                    ForEach(AccountManager.instance.mailboxes) { mailbox in
                        Toggle(isOn: Binding(get: {
                            notificationsEnabled && subscribedTopics?.contains(mailbox.notificationTopicName) == true
                        }, set: { on in
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
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 16)
        }
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
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            settingsNotificationEnabled { enabled in
                showWarning = !enabled
            }
        }
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
        .customAlert(isPresented: $showAlertNotification) {
            SettingsNotificationsInstructionsView()
        }
        .matomoView(view: [MatomoUtils.View.settingsView.displayName, "Notifications"])
    }

    func currentTopics() async {
        let currentSubscription = await notificationService.subscriptionForUser(id: AccountManager.instance.currentUserId)
        withAnimation {
            self.subscribedTopics = currentSubscription?.topics
        }
    }

    func updateTopicsForCurrentUserIfNeeded() {
        Task {
            guard let currentApiFetcher = AccountManager.instance.currentMailboxManager?.apiFetcher,
                  let subscribedTopics else { return }
            await notificationService.updateTopicsIfNeeded(subscribedTopics, userApiFetcher: currentApiFetcher)
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

struct SettingsNotificationsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsNotificationsView()
    }
}
