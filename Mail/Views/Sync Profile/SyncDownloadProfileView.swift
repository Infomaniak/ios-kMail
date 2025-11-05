/*
 Infomaniak Mail - iOS App
 Copyright (C) 2024 Infomaniak Network SA

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
import InfomaniakCoreCommonUI
import InfomaniakCoreSwiftUI
import InfomaniakDI
import MailCore
import MailCoreUI
import MailResources
import SwiftModalPresentation
import SwiftUI

struct SyncDownloadProfileView: View {
    @LazyInjectService private var server: ConfigWebServer

    @AppStorage(UserDefaults.shared.key(.accentColor)) private var accentColor = DefaultPreferences.accentColor

    @EnvironmentObject private var mailboxManager: MailboxManager

    @ModalState(context: ContextKeys.sync) private var isConfigWebViewPresented = false
    @State private var isDownloadingConfig = false

    @Binding var navigationPath: [SyncProfileStep]

    var body: some View {
        VStack(spacing: IKPadding.medium) {
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
        .padding(value: .large)
        .toolbar {
            ToolbarItem(placement: .principal) {
                SyncStepToolbarItem(step: 1, totalSteps: 3)
            }
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: IKPadding.mini) {
                Button(MailResourcesStrings.Localizable.buttonDownload) {
                    @InjectService var matomo: MatomoUtils
                    matomo.track(eventWithCategory: .syncAutoConfig, name: "download")
                    downloadProfile()
                }
                .buttonStyle(.ikBorderedProminent)
                .ikButtonFullWidth(true)
                .controlSize(.large)
                .ikButtonLoading(isDownloadingConfig)
            }
            .padding(.horizontal, value: .large)
            .padding(.bottom, IKPadding.onBoardingBottomButtons)
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
