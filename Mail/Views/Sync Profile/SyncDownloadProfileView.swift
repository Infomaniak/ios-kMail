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

import InfomaniakCoreUI
import InfomaniakDI
import MailCore
import MailResources
import SwiftUI

struct SyncDownloadProfileView: View {
    @LazyInjectService private var matomo: MatomoUtils
    @LazyInjectService private var server: ConfigWebServer

    @AppStorage(UserDefaults.shared.key(.accentColor)) private var accentColor = DefaultPreferences.accentColor

    @EnvironmentObject private var mailboxManager: MailboxManager

    @State private var isConfigWebViewPresented = false
    @State private var isDownloadingConfig = false

    @Binding var navigationPath: [SyncProfileStep]

    var body: some View {
        VStack(spacing: UIPadding.regular) {
            Text(MailResourcesStrings.Localizable.syncTutorialDownloadProfileTitle)
                .textStyle(.header2)
                .multilineTextAlignment(.center)
            Text(MailResourcesStrings.Localizable.syncTutorialDownloadProfileDescription)
                .textStyle(.bodySecondary)

            Spacer(minLength: 16)
            MailResourcesAsset.syncTutorial0.swiftUIImage
                .resizable()
                .aspectRatio(contentMode: .fit)
            Spacer()
        }
        .padding(value: .medium)
        .toolbar {
            ToolbarItem(placement: .principal) {
                SyncStepToolbarItem(step: 1, totalSteps: 3)
            }
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: UIPadding.small) {
                Button(MailResourcesStrings.Localizable.buttonDownload) {
                    matomo.track(eventWithCategory: .syncAutoConfig, name: "download")
                    downloadProfile()
                }
                .buttonStyle(.ikPlain)
                .ikButtonFullWidth(true)
                .controlSize(.large)
                .ikButtonLoading(isDownloadingConfig)
            }
            .padding(.horizontal, value: .medium)
            .padding(.bottom, UIPadding.onBoardingBottomButtons)
        }
        .sheet(isPresented: $isConfigWebViewPresented) {
            navigationPath.append(.copyPassword)
            server.stop()
        } content: {
            DownloadConfigSafariView()
                .ignoresSafeArea()
        }
        .onOpenURL { url in
            if url.scheme == "com.infomaniak.mail.profile-callback" {
                isConfigWebViewPresented = false
            }
        }
    }

    func downloadProfile() {
        Task {
            isDownloadingConfig = true
            await tryOrDisplayError {
                let downloadedConfigURL = try await mailboxManager.apiFetcher.downloadSyncProfile(
                    syncContacts: true,
                    syncCalendar: true
                )
                server.start(
                    configURL: downloadedConfigURL,
                    buttonTitle: MailResourcesStrings.Localizable.buttonBackToApp,
                    buttonBackgroundColor: accentColor.primary.color,
                    buttonForegroundColor: accentColor.onAccent.color,
                    backgroundColor: accentColor.secondary.color
                )
                isDownloadingConfig = false
                isConfigWebViewPresented = true
            }
        }
    }
}

#Preview {
    NavigationView {
        SyncDownloadProfileView(navigationPath: .constant([]))
    }
    .navigationViewStyle(.stack)
}
