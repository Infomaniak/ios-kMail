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
import InfomaniakLogin
import MailCore
import MailResources
import SwiftUI

struct Slide: Identifiable {
    let id: Int
    let backgroundImage: Image
    let animationFile: String
    let title: String
    let description: String
    let lottieConfiguration: LottieConfiguration

    static let allSlides = [
        Slide(
            id: 1,
            backgroundImage: Image(resource: MailResourcesAsset.onboardingBackground1),
            animationFile: "illu_1",
            title: MailResourcesStrings.Localizable.onBoardingTitle1,
            description: "",
            lottieConfiguration: LottieConfiguration(id: 1, loopMode: .playOnce, loopFrameStart: 54, loopFrameEnd: 138)
        ),
        Slide(
            id: 2,
            backgroundImage: Image(resource: MailResourcesAsset.onboardingBackground2),
            animationFile: "illu_2",
            title: MailResourcesStrings.Localizable.onBoardingTitle2,
            description: MailResourcesStrings.Localizable.onBoardingDescription2,
            lottieConfiguration: LottieConfiguration(id: 2, loopMode: .playOnce, loopFrameStart: 108, loopFrameEnd: 253)
        ),
        Slide(
            id: 3,
            backgroundImage: Image(resource: MailResourcesAsset.onboardingBackground3),
            animationFile: "illu_3",
            title: MailResourcesStrings.Localizable.onBoardingTitle3,
            description: MailResourcesStrings.Localizable.onBoardingDescription3,
            lottieConfiguration: LottieConfiguration(id: 3, loopMode: .playOnce, loopFrameStart: 118, loopFrameEnd: 225)
        ),
        Slide(
            id: 4,
            backgroundImage: Image(resource: MailResourcesAsset.onboardingBackground4),
            animationFile: "illu_4",
            title: MailResourcesStrings.Localizable.onBoardingTitle4,
            description: MailResourcesStrings.Localizable.onBoardingDescription4,
            lottieConfiguration: LottieConfiguration(id: 4, loopMode: .playOnce, loopFrameStart: 127, loopFrameEnd: 236)
        )
    ]
}

struct OnboardingView: View {
    @Environment(\.window) private var window
    @Environment(\.dismiss) private var dismiss

    @State private var selection: Int
    @State private var presentAlert = false
    @State private var isLoading = false

    private var isScrollEnabled: Bool
    private var slides = Slide.allSlides

    init(page: Int = 1, isScrollEnabled: Bool = true) {
        _selection = State(initialValue: page)
        self.isScrollEnabled = isScrollEnabled
        UIPageControl.appearance().currentPageIndicatorTintColor = .tintColor
        UIPageControl.appearance().pageIndicatorTintColor = MailResourcesAsset.separatorColor.color
    }

    var body: some View {
        VStack(spacing: 0) {
            Group {
                if !isScrollEnabled, let slide = slides.first { $0.id == selection } {
                    SlideView(slide: slide)
                } else {
                    TabView(selection: $selection) {
                        ForEach(slides) { slide in
                            SlideView(slide: slide)
                                .tag(slide.id)
                        }
                    }
                    .tabViewStyle(.page)
                }
            }
            .ignoresSafeArea(edges: .top)
            .overlay(alignment: .top) {
                Image(resource: MailResourcesAsset.logoText)
                    .resizable()
                    .scaledToFit()
                    .frame(height: Constants.onboardingLogoHeight)
                    .padding(.top, 28)
            }

            VStack(spacing: 24) {
                if selection == slides.count {
                    // Show login button
                    LargeButton(title: MailResourcesStrings.Localizable.buttonLogin, isLoading: isLoading, action: login)
                    Button {
                        // TODO: Create account
                        showWorkInProgressSnackBar()
                    } label: {
                        Text(MailResourcesStrings.Localizable.buttonCreateAccount)
                            .textStyle(.bodyMediumAccent)
                    }
                } else {
                    Button {
                        withAnimation {
                            selection += 1
                        }
                    } label: {
                        Image(systemName: "arrow.right")
                            .imageScale(.large)
                            .font(.title3.weight(.semibold))
                            .frame(width: 36, height: 46)
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.capsule)
                }
            }
            .frame(height: Constants.onboardingButtonHeight + Constants.onboardingBottomButtonPadding, alignment: .top)
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

    private func login() {
        isLoading = true
        InfomaniakLogin.asWebAuthenticationLoginFrom(useEphemeralSession: true) { result in
            switch result {
            case let .success(result):
                loginSuccessful(code: result.code, codeVerifier: result.verifier)
            case let .failure(error):
                loginFailed(error: error)
            }
        }
    }

    private func loginSuccessful(code: String, codeVerifier verifier: String) {
        MatomoUtils.track(eventWithCategory: .account, name: "loggedIn")
        let previousAccount = AccountManager.instance.currentAccount
        Task {
            do {
                _ = try await AccountManager.instance.createAndSetCurrentAccount(code: code, codeVerifier: verifier)
                MatomoUtils.connectUser()
                await (self.window?.windowScene?.delegate as? SceneDelegate)?.showMainView()
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
