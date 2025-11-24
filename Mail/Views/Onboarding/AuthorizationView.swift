/*
 Infomaniak Mail - iOS App
 Copyright (C) 2022 Infomaniak Network SA

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

import Contacts
import DesignSystem
import DotLottie
import InfomaniakCoreCommonUI
import InfomaniakCoreSwiftUI
import InfomaniakDI
import InfomaniakOnboarding
import MailCore
import MailResources
import SwiftUI

extension SlideCollectionViewCell {
    func setThemeFor(colorScheme: ColorScheme, accentColor: AccentColor, dotLottieViewModel: DotLottieAnimation) {
        switch (colorScheme, accentColor) {
        case (.light, .pink):
            dotLottieViewModel.resetTheme()
        case (.light, .blue):
            dotLottieViewModel.setTheme("Blue-Light")
        case (.dark, .pink):
            dotLottieViewModel.setTheme("Pink-Dark")
        case (.dark, .blue):
            dotLottieViewModel.setTheme("Blue-Dark")
        case (_, _):
            dotLottieViewModel.resetTheme()
        }
    }
}

extension Slide {
    static let authorizationSlides = [
        Slide(backgroundImage: MailResourcesAsset.onboardingBackground1.image,
              backgroundImageTintColor: UserDefaults.shared.accentColor.secondary.color,
              content: .dotLottieAnimation(IKDotLottieConfiguration(
                  filename: "addressBookPermission",
                  bundle: MailResourcesResources.bundle,
                  isLooping: true,
                  mode: .bounce
              )),
              bottomView: OnboardingTextView(
                  title: MailResourcesStrings.Localizable.onBoardingContactsTitle,
                  description: MailResourcesStrings.Localizable.onBoardingContactsDescription
              )),
        Slide(backgroundImage: MailResourcesAsset.onboardingBackground2.image,
              backgroundImageTintColor: UserDefaults.shared.accentColor.secondary.color,
              content: .dotLottieAnimation(IKDotLottieConfiguration(
                  filename: "notificationPermission",
                  bundle: MailResourcesResources.bundle,
                  isLooping: true,
                  mode: .bounce
              )),
              bottomView: OnboardingTextView(
                  title: MailResourcesStrings.Localizable.onBoardingNotificationsTitle,
                  description: MailResourcesStrings.Localizable.onBoardingNotificationsDescription
              ))
    ]
}

enum AuthorizationSlide: Int {
    case contacts
    case notifications
}

struct AuthorizationView: View {
    @InjectService private var accountManager: AccountManager

    @EnvironmentObject private var navigationState: RootViewState

    @State private var selection = AuthorizationSlide.contacts.rawValue
    @State private var isScrollEnabled = false

    private var slides = Slide.authorizationSlides

    var body: some View {
        WaveView(slides: slides, selectedSlide: $selection, isScrollEnabled: isScrollEnabled, isPageIndicatorHidden: true) { _ in
            VStack(spacing: IKPadding.mini) {
                Button(MailResourcesStrings.Localizable.contentDescriptionButtonNext, action: nextButtonClicked)
                    .buttonStyle(.ikBorderedProminent)
                    .controlSize(.large)
                    .ikButtonFullWidth(true)
            }
            .padding(.horizontal, value: .large)
            .padding(.bottom, IKPadding.onBoardingBottomButtons)
        }
        .ignoresSafeArea()
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
            isScrollEnabled = true
            withAnimation {
                selection = AuthorizationSlide.notifications.rawValue
                isScrollEnabled = false
            }
            if accessAllowed != nil {
                try await accountManager.currentMailboxManager?.contactManager.refreshContactsAndAddressBooks()
            }
        }
    }

    func requestNotificationsAuthorization() {
        Task {
            await NotificationsHelper.askForPermissions()
            await navigationState.transitionToMainViewIfPossible(targetAccount: nil, targetMailbox: nil)
        }
    }
}

#Preview {
    AuthorizationView()
}
