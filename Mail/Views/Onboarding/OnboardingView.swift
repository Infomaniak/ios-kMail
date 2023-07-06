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
}

@MainActor
class LoginHandler: InfomaniakLoginDelegate, ObservableObject {
    @LazyInjectService var loginService: InfomaniakLoginable
    @LazyInjectService var matomo: MatomoUtils

    @Published var isLoading = false
    @Published var isPresentingErrorAlert = false

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
        matomo.track(eventWithCategory: .account, name: "openCreationWebview")
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
        let previousAccount = AccountManager.instance.currentAccount
        Task {
            do {
                _ = try await AccountManager.instance.createAndSetCurrentAccount(code: code, codeVerifier: verifier)
                UIApplication.shared.registerForRemoteNotifications()
            } catch let error as MailError where error == MailError.noMailbox {
                // sceneDelegate?.showNoMailboxView()
            } catch {
                if let previousAccount = previousAccount {
                    AccountManager.instance.switchAccount(newAccount: previousAccount)
                }
                IKSnackBar.showSnackBar(message: error.localizedDescription)
            }
            isLoading = false
        }
    }

    private func loginFailed(error: Error) {
        isLoading = false
        guard (error as? ASWebAuthenticationSessionError)?.code != .canceledLogin else { return }
        isPresentingErrorAlert = true
    }
}

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss

    @AppStorage(UserDefaults.shared.key(.accentColor)) private var accentColor = DefaultPreferences.accentColor

    @State private var selection: Int
    @State private var isPresentingCreateAccount = false
    @StateObject private var loginHandler = LoginHandler()
    private var isScrollEnabled: Bool
    private var slides = Slide.onBoardingSlides

    init(page: Int = 1, isScrollEnabled: Bool = true) {
        _selection = State(initialValue: page)
        self.isScrollEnabled = isScrollEnabled
        UIPageControl.appearance().currentPageIndicatorTintColor = .tintColor
        UIPageControl.appearance().pageIndicatorTintColor = MailResourcesAsset.elementsColor.color
    }

    var body: some View {
        VStack(spacing: 0) {
            Group {
                if !isScrollEnabled, let slide = slides.first { $0.id == selection } {
                    SlideView(slide: slide, updateAnimationColors: updateAnimationColors)
                } else {
                    TabView(selection: $selection) {
                        ForEach(slides) { slide in
                            SlideView(slide: slide, updateAnimationColors: updateAnimationColors)
                                .tag(slide.id)
                        }
                    }
                    .tabViewStyle(.page)
                    .ignoresSafeArea(edges: .top)
                }
            }
            .overlay(alignment: .top) {
                MailResourcesAsset.logoText.swiftUIImage
                    .resizable()
                    .scaledToFit()
                    .frame(height: UIConstants.onboardingLogoHeight)
                    .padding(.top, UIConstants.onboardingLogoPaddingTop)
            }

            VStack(spacing: 24) {
                if selection == slides.count {
                    MailButton(label: MailResourcesStrings.Localizable.buttonLogin) {
                        loginHandler.login()
                    }
                    .mailButtonFullWidth(true)
                    .mailButtonLoading(loginHandler.isLoading)

                    MailButton(label: MailResourcesStrings.Localizable.buttonCreateAccount) {
                        isPresentingCreateAccount.toggle()
                    }
                    .mailButtonStyle(.link)
                    .disabled(loginHandler.isLoading)
                } else {
                    MailButton(icon: MailResourcesAsset.fullArrowRight) {
                        withAnimation {
                            selection += 1
                        }
                    }
                    .mailButtonIconSize(UIConstants.onboardingArrowIconSize)
                }
            }
            .frame(height: UIConstants.onboardingButtonHeight + UIConstants.onboardingBottomButtonPadding, alignment: .top)
            .padding(.horizontal, 24)
        }
        .overlay(alignment: .topLeading) {
            if !isScrollEnabled {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .resizable()
                }
                .frame(width: 24, height: 24)
                .padding(.top, 16)
                .padding(.leading, 24)
            }
        }
        .alert(MailResourcesStrings.Localizable.errorLoginTitle, isPresented: $loginHandler.isPresentingErrorAlert) {
            // Use default button
        } message: {
            Text(MailResourcesStrings.Localizable.errorLoginDescription)
        }
        .sheet(isPresented: $isPresentingCreateAccount) {
            RegisterView(registrationProcess: .mail) { viewController in
                guard let viewController else { return }
                loginHandler.loginAfterAccountCreation(from: viewController)
            }
        }
        .onAppear {
            if UIDevice.current.userInterfaceIdiom == .phone {
                UIDevice.current
                    .setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
                AppDelegate.orientationLock = .portrait
                UIViewController.attemptRotationToDeviceOrientation()
            }
        }
        .defaultAppStorage(.shared)
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
