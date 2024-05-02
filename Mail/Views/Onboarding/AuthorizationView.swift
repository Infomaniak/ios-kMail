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

import Contacts
import InfomaniakCoreUI
import InfomaniakDI
import MailCore
import MailResources
import SwiftUI

enum AuthorizationSlide: Int {
    case contacts
    case notifications
}

struct AuthorizationView: View {
    @LazyInjectService private var accountManager: AccountManager

    @EnvironmentObject private var navigationState: RootViewState

    @State private var selection = AuthorizationSlide.contacts.rawValue
    @State private var isScrollDisabled = true

    private var slides = Slide.authorizationSlides

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $selection) {
                ForEach(slides) { slide in
                    SlideView(slide: slide)
                        .tag(slide.id)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea(edges: .top)
            .disabled(isScrollDisabled)
            .overlay(alignment: .top) {
                MailResourcesAsset.logoText.swiftUIImage
                    .resizable()
                    .scaledToFit()
                    .frame(height: UIConstants.onboardingLogoHeight)
                    .padding(.top, UIPadding.onBoardingLogoTop)
            }

            VStack(spacing: UIPadding.small) {
                Button(MailResourcesStrings.Localizable.contentDescriptionButtonNext, action: nextButtonClicked)
                    .buttonStyle(.ikPlain)
                    .controlSize(.large)
                    .ikButtonFullWidth(true)
            }
            .padding(.horizontal, value: .medium)
            .padding(.bottom, UIPadding.onBoardingBottomButtons)
        }
        .matomoView(view: [MatomoUtils.View.onboarding.displayName, "Authorization"])
        .task(id: accountManager.currentMailboxManager) {
            await fetchFirstMessagesInBackground()
        }
    }

    private func fetchFirstMessagesInBackground() async {
        guard let currentMailboxManager = accountManager.currentMailboxManager,
              currentMailboxManager.getFolder(with: .inbox)?.cursor == nil else {
            return
        }

        try? await currentMailboxManager.refreshAllFolders()

        guard let inboxFolder = currentMailboxManager.getFolder(with: .inbox)?.freezeIfNeeded() else {
            return
        }

        await currentMailboxManager.refreshFolderContent(inboxFolder)
    }

    private func nextButtonClicked() {
        if selection == AuthorizationSlide.contacts.rawValue {
            requestContactsAuthorization()
        } else {
            requestNotificationsAuthorization()
        }
    }

    private func requestContactsAuthorization() {
        Task {
            let accessAllowed = await (try? CNContactStore().requestAccess(for: .contacts))
            isScrollDisabled = false
            withAnimation {
                selection = AuthorizationSlide.notifications.rawValue
                isScrollDisabled = true
            }
            if accessAllowed != nil {
                try await accountManager.currentMailboxManager?.contactManager.refreshContactsAndAddressBooks()
            }
        }
    }

    func requestNotificationsAuthorization() {
        Task {
            await NotificationsHelper.askForPermissions()
            navigationState.transitionToRootViewDestination(.mainView)
        }
    }
}

#Preview {
    AuthorizationView()
}
