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
import InfomaniakOnboarding
import Lottie
import MailCore
import MailCoreUI
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
    var lottieConfiguration: MailCoreUI.LottieConfiguration?

    static let onBoardingSlides = [Slide]()

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

extension SlideCollectionViewCell {
    func updateAnimationColors(configuration: IKLottieConfiguration) {
        guard let animation = illustrationAnimationView else { return }
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

struct TOnboardingView: UIViewControllerRepresentable {
    @AppStorage(UserDefaults.shared.key(.accentColor)) private var accentColor = DefaultPreferences.accentColor

    typealias UIViewControllerType = OnboardingViewController

    @State var selectedSlide = 0

    func makeUIViewController(context: Context) -> InfomaniakOnboarding.OnboardingViewController {
        let configuration = OnboardingConfiguration(
            headerImage: MailResourcesAsset.logoText.image,
            slides: slides,
            pageIndicatorColor: accentColor.primary.color,
            isScrollEnabled: true
        )

        let controller = OnboardingViewController(configuration: configuration)
        controller.delegate = context.coordinator
        context.coordinator.currentAccentColor = accentColor
        context.coordinator.currentColorScheme = context.environment.colorScheme

        return controller
    }

    func updateUIViewController(_ uiViewController: InfomaniakOnboarding.OnboardingViewController, context: Context) {
        if uiViewController.pageIndicator.currentPage != selectedSlide {
            uiViewController.setSelectedSlide(index: selectedSlide)
        }

        let coordinator = context.coordinator

        if coordinator.currentAccentColor != accentColor || coordinator.currentColorScheme != context.environment.colorScheme {
            coordinator.invalidateColors()

            let newColorScheme = context.environment.colorScheme
            uiViewController.currentSlideViewCell?.backgroundImageView.tintColor = newColorScheme == .dark ? MailResourcesAsset
                .backgroundSecondaryColor.color : accentColor.secondary.color
            uiViewController.pageIndicator.currentPageIndicatorTintColor = accentColor.primary.color
            if let configuration = slides[selectedSlide].animationConfiguration {
                uiViewController.currentSlideViewCell?.updateAnimationColors(configuration: configuration)
            }

            coordinator.currentAccentColor = accentColor
            coordinator.currentColorScheme = newColorScheme
        }
    }

    var slides: [InfomaniakOnboarding.Slide] {
        return [
            InfomaniakOnboarding.Slide(
                backgroundImage: MailResourcesAsset.onboardingBackground1.image,
                backgroundImageTintColor: accentColor.secondary.color,
                illustrationImage: nil,
                animationConfiguration: IKLottieConfiguration(
                    id: 1,
                    filename: "illu_onboarding_1",
                    bundle: MailResourcesResources.bundle,
                    loopFrameStart: 54,
                    loopFrameEnd: 138,
                    lottieConfiguration: .init(renderingEngine: .mainThread)
                ),
                bottomViewController: UIHostingController(rootView: OnboardingThemePickerView(title: MailResourcesStrings
                        .Localizable.onBoardingTitle1))
            ),
            InfomaniakOnboarding.Slide(
                backgroundImage: MailResourcesAsset.onboardingBackground2.image,
                backgroundImageTintColor: accentColor.secondary.color,
                illustrationImage: nil,
                animationConfiguration: IKLottieConfiguration(
                    id: 2,
                    filename: "illu_onboarding_2",
                    bundle: MailResourcesResources.bundle,
                    loopFrameStart: 108,
                    loopFrameEnd: 253,
                    lottieConfiguration: .init(renderingEngine: .mainThread)
                ),
                bottomViewController: UIHostingController(rootView: OnboardingTextView(
                    title: MailResourcesStrings.Localizable.onBoardingTitle2,
                    description: MailResourcesStrings.Localizable.onBoardingDescription2
                ))
            ),
            InfomaniakOnboarding.Slide(
                backgroundImage: MailResourcesAsset.onboardingBackground3.image,
                backgroundImageTintColor: accentColor.secondary.color,
                illustrationImage: nil,
                animationConfiguration: IKLottieConfiguration(
                    id: 3,
                    filename: "illu_onboarding_3",
                    bundle: MailResourcesResources.bundle,
                    loopFrameStart: 111,
                    loopFrameEnd: 187,
                    lottieConfiguration: .init(renderingEngine: .mainThread)
                ),
                bottomViewController: UIHostingController(rootView: OnboardingTextView(
                    title: MailResourcesStrings.Localizable.onBoardingTitle3,
                    description: MailResourcesStrings.Localizable.onBoardingDescription3
                ))
            ),
            InfomaniakOnboarding.Slide(
                backgroundImage: MailResourcesAsset.onboardingBackground4.image,
                backgroundImageTintColor: accentColor.secondary.color,
                illustrationImage: nil,
                animationConfiguration: IKLottieConfiguration(
                    id: 4,
                    filename: "illu_onboarding_4",
                    bundle: MailResourcesResources.bundle,
                    loopFrameStart: 127,
                    loopFrameEnd: 236,
                    lottieConfiguration: .init(renderingEngine: .mainThread)
                ),
                bottomViewController: UIHostingController(rootView: OnboardingTextView(
                    title: MailResourcesStrings.Localizable.onBoardingTitle4,
                    description: MailResourcesStrings.Localizable.onBoardingDescription4
                ))
            )
        ]
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(selectedSlide: $selectedSlide, slides: slides)
    }

    class Coordinator: OnboardingViewControllerDelegate {
        var currentAccentColor: AccentColor?
        var currentColorScheme: ColorScheme?

        let selectedSlide: Binding<Int>
        let slides: [InfomaniakOnboarding.Slide]
        var colorUpdateNeededAtIndex = Set<Int>()

        init(selectedSlide: Binding<Int>, slides: [InfomaniakOnboarding.Slide]) {
            self.selectedSlide = selectedSlide
            self.slides = slides
        }

        func bottomViewForIndex(_ index: Int) -> UIView? {
            let hostingViewController = UIHostingController(rootView: OnboardingBottomButtonsView(
                selection: selectedSlide,
                slideCount: slides.count
            ))
            return hostingViewController.view
        }

        func shouldAnimateBottomViewForIndex(_ index: Int) -> Bool {
            return index == slides.count - 1 || (index == slides.count - 2 && selectedSlide.wrappedValue == slides.count - 1)
        }

        func willDisplaySlideViewCell(_ slideViewCell: SlideCollectionViewCell, at index: Int) {
            slideViewCell.backgroundImageView.tintColor = slideViewCell.traitCollection.userInterfaceStyle == .dark ?
                MailResourcesAsset.backgroundSecondaryColor.color :
                UserDefaults.shared.accentColor.secondary.color

            if let configuration = slides[index].animationConfiguration,
               colorUpdateNeededAtIndex.contains(index) {
                slideViewCell.updateAnimationColors(configuration: configuration)
                colorUpdateNeededAtIndex.remove(index)
            }
        }

        func invalidateColors() {
            for i in 0 ..< slides.count {
                colorUpdateNeededAtIndex.insert(i)
            }
        }

        func currentIndexChanged(newIndex: Int) {
            DispatchQueue.main.async { [weak self] in
                self?.selectedSlide.wrappedValue = newIndex
            }
        }
    }
}

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss

    @LazyInjectService var orientationManager: OrientationManageable

    @State private var selection: Int

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
            TOnboardingView()
                .ignoresSafeArea()
        }
        .overlay(alignment: .topLeading) {
            if !isScrollEnabled {
                CloseButton(size: .regular, dismissAction: dismiss)
                    .padding(.top, UIPadding.onBoardingLogoTop)
                    .padding(.top, value: .verySmall)
                    .padding(.leading, value: .medium)
            }
        }
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

    // MARK: - Private methods

    private func updateAnimationColors(_ animation: LottieAnimationView, _ configuration: MailCoreUI.LottieConfiguration) {
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
