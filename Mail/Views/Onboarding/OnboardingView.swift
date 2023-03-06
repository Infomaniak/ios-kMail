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
import InfomaniakCore
import InfomaniakCoreUI
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
    var asset: MailResourcesImages?
    var lottieConfiguration: LottieConfiguration?

    static let onBoardingSlides = [
        Slide(
            id: 1,
            backgroundImage: Image(resource: MailResourcesAsset.onboardingBackground1),
            title: MailResourcesStrings.Localizable.onBoardingTitle1,
            showPicker: true,
            lottieConfiguration: LottieConfiguration(id: 1, filename: "illu_onboarding_1", loopFrameStart: 54, loopFrameEnd: 138)
        ),
        Slide(
            id: 2,
            backgroundImage: Image(resource: MailResourcesAsset.onboardingBackground2),
            title: MailResourcesStrings.Localizable.onBoardingTitle2,
            description: MailResourcesStrings.Localizable.onBoardingDescription2,
            lottieConfiguration: LottieConfiguration(id: 2, filename: "illu_onboarding_2", loopFrameStart: 108, loopFrameEnd: 253)
        ),
        Slide(
            id: 3,
            backgroundImage: Image(resource: MailResourcesAsset.onboardingBackground3),
            title: MailResourcesStrings.Localizable.onBoardingTitle3,
            description: MailResourcesStrings.Localizable.onBoardingDescription3,
            lottieConfiguration: LottieConfiguration(id: 3, filename: "illu_onboarding_3", loopFrameStart: 111, loopFrameEnd: 187)
        ),
        Slide(
            id: 4,
            backgroundImage: Image(resource: MailResourcesAsset.onboardingBackground4),
            title: MailResourcesStrings.Localizable.onBoardingTitle4,
            description: MailResourcesStrings.Localizable.onBoardingDescription4,
            lottieConfiguration: LottieConfiguration(id: 4, filename: "illu_onboarding_4", loopFrameStart: 127, loopFrameEnd: 236)
        )
    ]
}

struct OnboardingView: View {
    @LazyInjectService var loginService: InfomaniakLogin

    @Environment(\.window) private var window
    @Environment(\.dismiss) private var dismiss

    @AppStorage(UserDefaults.shared.key(.accentColor)) private var accentColor = DefaultPreferences.accentColor

    @State private var selection: Int
    @State private var presentAlert = false
    @State private var isLoading = false

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
                Image(resource: MailResourcesAsset.logoText)
                    .resizable()
                    .scaledToFit()
                    .frame(height: Constants.onboardingLogoHeight)
                    .padding(.top, Constants.onboardingLogoPaddingTop)
            }

            VStack(spacing: 24) {
                if selection == slides.count {
                    // Show login button
                    MailButton(label: MailResourcesStrings.Localizable.buttonLogin, action: login)
                        .mailButtonFullWidth(true)
                        .disabled(isLoading)

                    MailButton(label: MailResourcesStrings.Localizable.buttonCreateAccount) {
                        // TODO: Create account
                        showWorkInProgressSnackBar()
                    }
                    .mailButtonStyle(.link)
                } else {
                    MailButton(icon: MailResourcesAsset.fullArrowRight) {
                        withAnimation {
                            selection += 1
                        }
                    }
                    .mailButtonIconSize(Constants.onboardingArrowIconSize)
                }
            }
            .frame(height: Constants.onboardingButtonHeight + Constants.onboardingBottomButtonPadding, alignment: .top)
            .padding(.horizontal, 24)
        }
        .overlay(alignment: .topLeading, content: {
            if !isScrollEnabled {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .resizable()
                }
                .frame(width: 20, height: 20)
                .padding(16)
            }
        })
        .alert(MailResourcesStrings.Localizable.errorLoginTitle, isPresented: $presentAlert) {
            // Use default button
        } message: {
            Text(MailResourcesStrings.Localizable.errorLoginDescription)
        }
        .onAppear {
            if UIDevice.current.userInterfaceIdiom == .phone {
                UIDevice.current
                    .setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
                AppDelegate.orientationLock = .portrait
                UIViewController.attemptRotationToDeviceOrientation()
            }
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

    private func login() {
        isLoading = true
        loginService.asWebAuthenticationLoginFrom(useEphemeralSession: true) { result in
            switch result {
            case let .success(result):
                loginSuccessful(code: result.code, codeVerifier: result.verifier)
            case let .failure(error):
                loginFailed(error: error)
            }
        }
    }

    private func loginSuccessful(code: String, codeVerifier verifier: String) {
        @InjectService var matomo: MatomoUtils

        matomo.track(eventWithCategory: .account, name: "loggedIn")
        let previousAccount = AccountManager.instance.currentAccount
        Task {
            do {
                _ = try await AccountManager.instance.createAndSetCurrentAccount(code: code, codeVerifier: verifier)
                await (self.window?.windowScene?.delegate as? SceneDelegate)?.showMainView()
                await UIApplication.shared.registerForRemoteNotifications()
                matomo.connectUser(userId: AccountManager.instance.currentUserId)
            } catch MailError.noMailbox {
                await (self.window?.windowScene?.delegate as? SceneDelegate)?.showNoMailboxView()
            } catch {
                if let previousAccount = previousAccount {
                    AccountManager.instance.switchAccount(newAccount: previousAccount)
                }
                await IKSnackBar.showSnackBar(message: error.localizedDescription)
            }
            isLoading = false
        }
    }

    private func loginFailed(error: Error) {
        print("Login error: \(error)")
        isLoading = false
        guard (error as? ASWebAuthenticationSessionError)?.code != .canceledLogin else { return }
        presentAlert = true
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
