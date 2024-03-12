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

import AuthenticationServices
import InfomaniakCoreUI
import InfomaniakCreateAccount
import InfomaniakDI
import InfomaniakLogin
import Lottie
import MailCore
import MailResources
import SwiftModalPresentation
import SwiftUI

struct Slide: Identifiable {
    let id: Int
    let backgroundImage: Image
    let title: String
    var description: String?
    var showPicker = false
    var asset: Image?
    var lottieConfiguration: LottieConfiguration?

    static let onBoardingSlides = [
        Slide(
            id: 1,
            backgroundImage: MailResourcesAsset.onboardingBackground1.swiftUIImage,
            title: MailResourcesStrings.Localizable.onBoardingTitle1,
            showPicker: true,
            lottieConfiguration: LottieConfiguration(id: 1, filename: "illu_onboarding_1", loopFrameStart: 54, loopFrameEnd: 138)
        ),
        Slide(
            id: 2,
            backgroundImage: MailResourcesAsset.onboardingBackground2.swiftUIImage,
            title: MailResourcesStrings.Localizable.onBoardingTitle2,
            description: MailResourcesStrings.Localizable.onBoardingDescription2,
            lottieConfiguration: LottieConfiguration(id: 2, filename: "illu_onboarding_2", loopFrameStart: 108, loopFrameEnd: 253)
        ),
        Slide(
            id: 3,
            backgroundImage: MailResourcesAsset.onboardingBackground3.swiftUIImage,
            title: MailResourcesStrings.Localizable.onBoardingTitle3,
            description: MailResourcesStrings.Localizable.onBoardingDescription3,
            lottieConfiguration: LottieConfiguration(id: 3, filename: "illu_onboarding_3", loopFrameStart: 111, loopFrameEnd: 187)
        ),
        Slide(
            id: 4,
            backgroundImage: MailResourcesAsset.onboardingBackground4.swiftUIImage,
            title: MailResourcesStrings.Localizable.onBoardingTitle4,
            description: MailResourcesStrings.Localizable.onBoardingDescription4,
            lottieConfiguration: LottieConfiguration(id: 4, filename: "illu_onboarding_4", loopFrameStart: 127, loopFrameEnd: 236)
        )
    ]

    static let authorizationSlides = [
        Slide(
            id: AuthorizationSlide.contacts.rawValue,
            backgroundImage: MailResourcesAsset.onboardingBackground1.swiftUIImage,
            title: MailResourcesStrings.Localizable.onBoardingContactsTitle,
            description: MailResourcesStrings.Localizable.onBoardingContactsDescription,
            asset: MailResourcesAsset.authorizationContact.swiftUIImage
        ),
        Slide(
            id: AuthorizationSlide.notifications.rawValue,
            backgroundImage: MailResourcesAsset.onboardingBackground2.swiftUIImage,
            title: MailResourcesStrings.Localizable.onBoardingNotificationsTitle,
            description: MailResourcesStrings.Localizable.onBoardingNotificationsDescription,
            asset: MailResourcesAsset.authorizationNotification.swiftUIImage
        )
    ]
}

@MainActor
final class LoginHandler: InfomaniakLoginDelegate, ObservableObject {
    @LazyInjectService private var loginService: InfomaniakLoginable
    @LazyInjectService private var matomo: MatomoUtils
    @LazyInjectService private var remoteNotificationRegistrer: RemoteNotificationRegistrable
    @LazyInjectService private var accountManager: AccountManager
    @LazyInjectService private var snackbarPresenter: SnackBarPresentable

    @Published var isLoading = false
    @Published var isPresentingErrorAlert = false
    @Published var shouldShowEmptyMailboxesView = false

    nonisolated func didCompleteLoginWith(code: String, verifier: String) {
        Task {
            await loginSuccessful(code: code, codeVerifier: verifier)
        }
    }

    nonisolated func didFailLoginWith(error: Error) {
        Task {
            await loginFailed(error: error)
        }
    }

    func loginAfterAccountCreation(from viewController: UIViewController) {
        isLoading = true
        loginService.setupWebviewNavbar(
            title: MailResourcesStrings.Localizable.buttonLogin,
            titleColor: nil,
            color: nil,
            buttonColor: nil,
            clearCookie: false,
            timeOutMessage: nil
        )
        loginService.webviewLoginFrom(viewController: viewController,
                                      hideCreateAccountButton: true,
                                      delegate: self)
    }

    func login() {
        isLoading = true
        matomo.track(eventWithCategory: .account, name: "openLoginWebview")
        loginService.asWebAuthenticationLoginFrom(
            anchor: ASPresentationAnchor(),
            useEphemeralSession: true,
            hideCreateAccountButton: true
        ) { [weak self] result in
            switch result {
            case .success(let result):
                self?.loginSuccessful(code: result.code, codeVerifier: result.verifier)
            case .failure(let error):
                self?.loginFailed(error: error)
            }
        }
    }

    private func loginSuccessful(code: String, codeVerifier verifier: String) {
        matomo.track(eventWithCategory: .account, name: "loggedIn")
        let previousAccount = accountManager.getCurrentAccount()
        Task {
            do {
                _ = try await accountManager.createAndSetCurrentAccount(code: code, codeVerifier: verifier)
                remoteNotificationRegistrer.register()
            } catch let error as MailError where error == MailError.noMailbox {
                shouldShowEmptyMailboxesView = true
            } catch {
                if let previousAccount {
                    accountManager.switchAccount(newAccount: previousAccount)
                }
                snackbarPresenter.show(message: error.localizedDescription)
                SentryDebug.loginError(error: error, step: "createAndSetCurrentAccount")
            }
            isLoading = false
        }
    }

    private func loginFailed(error: Error) {
        isLoading = false
        guard (error as? ASWebAuthenticationSessionError)?.code != .canceledLogin else { return }
        isPresentingErrorAlert = true
        SentryDebug.loginError(error: error, step: "loginFailed")
    }
}

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var navigationState: RootViewState

    @LazyInjectService var orientationManager: OrientationManageable

    @State private var selection: Int
    @ModalState private var isPresentingCreateAccount = false
    @StateObject private var loginHandler = LoginHandler()

    private var isScrollEnabled: Bool
    private var slides = Slide.onBoardingSlides

    private var isLastSlide: Bool {
        selection == slides.count
    }

    init(page: Int = 1, isScrollEnabled: Bool = true) {
        _selection = State(initialValue: page)
        self.isScrollEnabled = isScrollEnabled
        UIPageControl.appearance().currentPageIndicatorTintColor = .tintColor
        UIPageControl.appearance().pageIndicatorTintColor = MailResourcesAsset.elementsColor.color
    }

    var body: some View {
        VStack(spacing: 0) {
            Group {
                if isScrollEnabled {
                    TabView(selection: $selection) {
                        ForEach(slides) { slide in
                            SlideView(slide: slide, updateAnimationColors: updateAnimationColors)
                                .tag(slide.id)
                        }
                    }
                    .tabViewStyle(.page)
                    .ignoresSafeArea(edges: .top)
                } else if let slide = slides.first(where: { $0.id == selection }) {
                    SlideView(slide: slide)
                }
            }
            .overlay(alignment: .top) {
                MailResourcesAsset.logoText.swiftUIImage
                    .resizable()
                    .scaledToFit()
                    .frame(height: UIConstants.onboardingLogoHeight)
                    .padding(.top, UIPadding.onBoardingLogoTop)
            }

            VStack(spacing: UIPadding.small) {
                Button(MailResourcesStrings.Localizable.buttonLogin) {
                    loginHandler.login()
                }
                .buttonStyle(.ikPlain)
                .ikButtonLoading(loginHandler.isLoading)

                Button(MailResourcesStrings.Localizable.buttonCreateAccount) {
                    isPresentingCreateAccount.toggle()
                }
                .buttonStyle(.ikLink())
                .disabled(loginHandler.isLoading)
            }
            .ikButtonFullWidth(true)
            .controlSize(.large)
            .opacity(isLastSlide ? 1 : 0)
            .overlay {
                if !isLastSlide {
                    Button {
                        withAnimation {
                            selection = min(slides.count, selection + 1)
                        }
                    } label: {
                        IKIcon(MailResourcesAsset.fullArrowRight, size: .large)
                    }
                    .buttonStyle(.ikSquare)
                    .controlSize(.large)
                }
            }
            .padding(.horizontal, value: .medium)
            .padding(.bottom, UIPadding.onBoardingBottomButtons)
        }
        .overlay(alignment: .topLeading) {
            if !isScrollEnabled {
                CloseButton(size: .medium, dismissAction: dismiss)
                    .padding(.top, UIPadding.onBoardingLogoTop)
                    .padding(.top, value: .verySmall)
                    .padding(.leading, value: .medium)
            }
        }
        .alert(MailResourcesStrings.Localizable.errorLoginTitle, isPresented: $loginHandler.isPresentingErrorAlert) {
            // Use default button
        } message: {
            Text(MailResourcesStrings.Localizable.errorLoginDescription)
        }
        .onAppear {
            if UIDevice.current.userInterfaceIdiom == .phone {
                UIDevice.current
                    .setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
                orientationManager.setOrientationLock(.portrait)
                UIViewController.attemptRotationToDeviceOrientation()
            }
        }
        .onChange(of: loginHandler.shouldShowEmptyMailboxesView) { shouldShowEmptyMailboxesView in
            if shouldShowEmptyMailboxesView {
                navigationState.transitionToRootViewDestination(.noMailboxes)
            }
        }
        .matomoView(view: [MatomoUtils.View.onboarding.displayName, "Main"])
        .sheet(isPresented: $isPresentingCreateAccount) {
            CreateAccountView(loginHandler: loginHandler)
        }
    }

    // MARK: - Private methods

    private func updateAnimationColors(_ animation: LottieAnimationView, _ configuration: LottieConfiguration) {
        IlluColors.onBoardingAllColors.forEach { $0.applyColors(to: animation) }

        if configuration.id == 2 || configuration.id == 3 || configuration.id == 4 {
            IlluColors.illuOnBoarding234Colors.forEach { $0.applyColors(to: animation) }
        }

        switch configuration.id {
        case 1:
            IlluColors.illuOnBoarding1Colors.forEach { $0.applyColors(to: animation) }
        case 2:
            IlluColors.illuOnBoarding2Colors.forEach { $0.applyColors(to: animation) }
        case 3:
            IlluColors.illuOnBoarding3Colors.forEach { $0.applyColors(to: animation) }
        case 4:
            IlluColors.illuOnBoarding4Colors.forEach { $0.applyColors(to: animation) }
        default:
            break
        }

        if UserDefaults.shared.accentColor == .pink {
            IlluColors.onBoardingPinkColors.forEach { $0.applyColors(to: animation) }

            if configuration.id == 2 || configuration.id == 3 || configuration.id == 4 {
                IlluColors.illuOnBoarding234PinkColors.forEach { $0.applyColors(to: animation) }
            }

            switch configuration.id {
            case 1:
                IlluColors.illuOnBoarding1PinkColors.forEach { $0.applyColors(to: animation) }
            case 2:
                IlluColors.illuOnBoarding2PinkColors.forEach { $0.applyColors(to: animation) }
            case 3:
                IlluColors.illu3PinkColors.forEach { $0.applyColors(to: animation) }
            case 4:
                IlluColors.illuOnBoarding4PinkColors.forEach { $0.applyColors(to: animation) }
            default:
                break
            }
        } else {
            IlluColors.onBoardingBlueColors.forEach { $0.applyColors(to: animation) }

            if configuration.id == 2 || configuration.id == 3 || configuration.id == 4 {
                IlluColors.illuOnBoarding234BlueColors.forEach { $0.applyColors(to: animation) }
            }

            switch configuration.id {
            case 1:
                IlluColors.illuOnBoarding1BlueColors.forEach { $0.applyColors(to: animation) }
            case 2:
                IlluColors.illuOnBoarding2BlueColors.forEach { $0.applyColors(to: animation) }
            case 3:
                IlluColors.illu3BlueColors.forEach { $0.applyColors(to: animation) }
            case 4:
                IlluColors.illuOnBoarding4BlueColors.forEach { $0.applyColors(to: animation) }
            default:
                break
            }
        }
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
            .previewDevice(PreviewDevice(rawValue: "iPhone 14 Pro"))
            .previewDisplayName("Onboarding - Dynamic Island")

        OnboardingView()
            .previewDevice(PreviewDevice(rawValue: "iPhone 14"))
            .previewDisplayName("Onboarding - Notch")

        OnboardingView()
            .previewDevice(PreviewDevice(rawValue: "iPhone SE (3rd generation)"))
            .previewDisplayName("Onboarding - Default")
    }
}
