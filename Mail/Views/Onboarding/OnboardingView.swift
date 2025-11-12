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

import AuthenticationServices
import InfomaniakConcurrency
import InfomaniakCore
import InfomaniakCoreCommonUI
import InfomaniakCreateAccount
import InfomaniakDeviceCheck
import InfomaniakDI
import InfomaniakLogin
import InfomaniakOnboarding
import InterAppLogin
import Lottie
import MailCore
import MailCoreUI
import MailResources
import SwiftModalPresentation
import SwiftUI

extension Slide {
    static var onboardingSlides: [Slide] {
        let accentColor = UserDefaults.shared.accentColor
        return [
            Slide(
                backgroundImage: MailResourcesAsset.onboardingBackground1.image,
                backgroundImageTintColor: accentColor.secondary.color,
                content: .animation(IKLottieConfiguration(
                    id: 1,
                    filename: "illu_onboarding_1",
                    bundle: MailResourcesResources.bundle,
                    loopFrameStart: 54,
                    loopFrameEnd: 138,
                    lottieConfiguration: .init(renderingEngine: .mainThread)
                )),
                bottomView: OnboardingThemePickerView(title: MailResourcesStrings.Localizable.onBoardingTitle1)
            ),
            Slide(
                backgroundImage: MailResourcesAsset.onboardingBackground2.image,
                backgroundImageTintColor: accentColor.secondary.color,
                content: .animation(IKLottieConfiguration(
                    id: 2,
                    filename: "illu_onboarding_2",
                    bundle: MailResourcesResources.bundle,
                    loopFrameStart: 108,
                    loopFrameEnd: 253,
                    lottieConfiguration: .init(renderingEngine: .mainThread)
                )),
                bottomView: OnboardingTextView(
                    title: MailResourcesStrings.Localizable.onBoardingTitle2,
                    description: MailResourcesStrings.Localizable.onBoardingDescription2
                )
            ),
            Slide(
                backgroundImage: MailResourcesAsset.onboardingBackground3.image,
                backgroundImageTintColor: accentColor.secondary.color,
                content: .animation(IKLottieConfiguration(
                    id: 3,
                    filename: "illu_onboarding_3",
                    bundle: MailResourcesResources.bundle,
                    loopFrameStart: 111,
                    loopFrameEnd: 187,
                    lottieConfiguration: .init(renderingEngine: .mainThread)
                )),
                bottomView: OnboardingTextView(
                    title: MailResourcesStrings.Localizable.onBoardingTitle3,
                    description: MailResourcesStrings.Localizable.onBoardingDescription3
                )
            ),
            Slide(
                backgroundImage: MailResourcesAsset.onboardingBackground4.image,
                backgroundImageTintColor: accentColor.secondary.color,
                content: .animation(IKLottieConfiguration(
                    id: 4,
                    filename: "illu_onboarding_4",
                    bundle: MailResourcesResources.bundle,
                    loopFrameStart: 127,
                    loopFrameEnd: 236,
                    lottieConfiguration: .init(renderingEngine: .mainThread)
                )),
                bottomView: OnboardingTextView(
                    title: MailResourcesStrings.Localizable.onBoardingTitle4,
                    description: MailResourcesStrings.Localizable.onBoardingDescription4
                )
            )
        ]
    }
}

enum MultiLoginResult {
    case success(token: ApiToken, mailboxes: [Mailbox], apiFetcher: ApiFetcher)
    case error(Error)
}

@MainActor
final class LoginHandler: InfomaniakLoginDelegate, ObservableObject {
    @LazyInjectService private var loginService: InfomaniakLoginable
    @LazyInjectService private var tokenService: InfomaniakNetworkLoginable
    @LazyInjectService private var matomo: MatomoUtils
    @LazyInjectService private var remoteNotificationRegistrer: RemoteNotificationRegistrable
    @LazyInjectService private var accountManager: AccountManager
    @LazyInjectService private var snackbarPresenter: IKSnackBarPresentable

    @Published var isLoading = false
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

    func loginWith(accounts: [ConnectedAccount]) {
        isLoading = true
        Task {
            defer { isLoading = false }

            let loginResults: [MultiLoginResult] = await accounts.asyncMap { account in
                do {
                    let derivatedToken = try await self.tokenService.derivateApiToken(for: account)

                    let (apiFetcher, mailboxes) = try await self.accountManager.createAccount(token: derivatedToken)
                    return .success(token: derivatedToken, mailboxes: mailboxes, apiFetcher: apiFetcher)
                } catch {
                    return .error(error)
                }
            }

            await loginWithSuccess(loginResults: loginResults)
            loginWithErrors(loginResults: loginResults)
        }
    }

    private func loginWithSuccess(loginResults: [MultiLoginResult]) async {
        await loginResults.asyncForEach { loginResult in
            guard case .success(let token, let mailboxes, let apiFetcher) = loginResult else { return }
            await self.accountManager.setCurrentAccount(token: token, mailboxes: mailboxes, apiFetcher: apiFetcher)
        }
    }

    private func loginWithErrors(loginResults: [MultiLoginResult]) {
        let errors: [Error] = loginResults.compactMap {
            if case .error(let error) = $0 {
                return error
            }
            return nil
        }

        for error in errors {
            if (error as? MailError) == MailError.noMailbox {
                shouldShowEmptyMailboxesView = true
            } else {
                snackbarPresenter.show(message: error.localizedDescription)
                SentryDebug.loginError(error: error, step: "createAndSetCurrentAccount")
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
                    accountManager.switchAccount(newUserId: previousAccount.userId)
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
        snackbarPresenter.show(message: MailResourcesStrings.Localizable.errorLoginDescription)
        SentryDebug.loginError(error: error, step: "loginFailed")
    }
}

extension SlideCollectionViewCell {
    func updateAnimationColors(configuration: IKLottieConfiguration) {
        guard case .airbnbLottieAnimationView(let animation, _) = illustrationAnimationViewContent else { return }
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

struct OnboardingView: View {
    @LazyInjectService private var orientationManager: OrientationManageable

    @State private var loginHandler = LoginHandler()
    @State private var selectedSlide = 0

    private let slides = Slide.onboardingSlides

    var body: some View {
        WaveView(slides: slides, selectedSlide: $selectedSlide, dismissHandler: nil) { index in
            index == slides.count - 1 || (index == slides.count - 2 && selectedSlide == slides.count - 1)
        } bottomView: { _ in
            OnboardingBottomButtonsView(
                loginHandler: loginHandler,
                selection: $selectedSlide,
                slideCount: slides.count
            )
        }
        .ignoresSafeArea()
        .onAppear {
            if UIDevice.current.userInterfaceIdiom == .phone {
                UIDevice.current
                    .setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
                orientationManager.setOrientationLock(.portrait)
                UIViewController.attemptRotationToDeviceOrientation()
            }
        }
        .matomoView(view: [MatomoUtils.View.onboarding.displayName, "Main"])
    }
}

#Preview {
    OnboardingView()
}
