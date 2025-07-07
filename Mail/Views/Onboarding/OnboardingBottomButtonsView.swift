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
import InfomaniakCoreSwiftUI
import InterAppLogin
import MailCore
import MailCoreUI
import MailResources
import SwiftModalPresentation
import SwiftUI

struct OnboardingBottomButtonsView: View {
    @EnvironmentObject private var navigationState: RootViewState

    @ModalState(context: ContextKeys.onboarding) private var isPresentingCreateAccount = false

    @ObservedObject var loginHandler: LoginHandler

    @Binding var selection: Int

    let slideCount: Int

    private var isLastSlide: Bool {
        return selection == slideCount - 1
    }

    var body: some View {
        VStack(spacing: IKPadding.mini) {
            ContinueWithAccountView(isLoading: loginHandler.isLoading) {
                Task { @MainActor in
                    // We have to wait for closing animation before opening the login WebView modally
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    loginHandler.login()
                }
            } onLoginWithAccountsPressed: { accounts in
                loginHandler.loginWith(accounts: accounts)
            } onCreateAccountPressed: {
                isPresentingCreateAccount = true
            }
        }
        .ikButtonFullWidth(true)
        .controlSize(.large)
        .opacity(isLastSlide ? 1 : 0)
        .overlay {
            if !isLastSlide {
                Button {
                    withAnimation {
                        selection = min(slideCount - 1, selection + 1)
                    }
                } label: {
                    MailResourcesAsset.fullArrowRight
                        .iconSize(.large)
                }
                .accessibilityLabel(MailResourcesStrings.Localizable.contentDescriptionButtonNext)
                .buttonStyle(.ikSquare)
                .controlSize(.large)
            }
        }
        .padding(.horizontal, value: .large)
        .padding(.bottom, IKPadding.onBoardingBottomButtons)
        .onChange(of: loginHandler.shouldShowEmptyMailboxesView) { shouldShowEmptyMailboxesView in
            if shouldShowEmptyMailboxesView {
                navigationState.transitionToRootViewState(.noMailboxes)
            }
        }
        .sheet(isPresented: $isPresentingCreateAccount) {
            CreateAccountView(loginHandler: loginHandler)
        }
    }
}

#Preview {
    OnboardingBottomButtonsView(loginHandler: LoginHandler(), selection: .constant(0), slideCount: 4)
}
