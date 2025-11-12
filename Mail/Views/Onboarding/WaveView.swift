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

import InfomaniakOnboarding
import MailCore
import MailResources
import SwiftUI

struct WaveView<BottomView: View>: UIViewControllerRepresentable {
    @AppStorage(UserDefaults.shared.key(.accentColor)) private var accentColor = DefaultPreferences.accentColor

    @Binding var selectedSlide: Int

    let isScrollEnabled: Bool
    let isPageIndicatorHidden: Bool
    let slides: [Slide]
    let headerImage: UIImage?

    let dismissHandler: (() -> Void)?

    let shouldAnimateBottomViewForIndex: (Int) -> Bool
    @ViewBuilder var bottomView: (Int) -> BottomView

    init(
        slides: [Slide],
        selectedSlide: Binding<Int>,
        isScrollEnabled: Bool = true,
        isPageIndicatorHidden: Bool = false,
        headerImage: UIImage? = MailResourcesAsset.logoText.image,
        dismissHandler: (() -> Void)? = nil,
        shouldAnimateBottomViewForIndex: @escaping (Int) -> Bool = { _ in return false },
        @ViewBuilder bottomView: @escaping (Int) -> BottomView
    ) {
        self.slides = slides
        self.headerImage = headerImage
        _selectedSlide = selectedSlide
        self.isScrollEnabled = isScrollEnabled
        self.dismissHandler = dismissHandler
        self.shouldAnimateBottomViewForIndex = shouldAnimateBottomViewForIndex
        self.bottomView = bottomView
        self.isPageIndicatorHidden = isPageIndicatorHidden
    }

    func makeUIViewController(context: Context) -> OnboardingViewController {
        let configuration = OnboardingConfiguration(
            headerImage: headerImage,
            slides: slides,
            pageIndicatorColor: accentColor.primary.color,
            isScrollEnabled: isScrollEnabled,
            dismissHandler: dismissHandler,
            isPageIndicatorHidden: isPageIndicatorHidden
        )

        let controller = OnboardingViewController(configuration: configuration)
        controller.delegate = context.coordinator
        context.coordinator.currentAccentColor = accentColor
        context.coordinator.currentColorScheme = context.environment.colorScheme
        context.coordinator.invalidateColors()

        return controller
    }

    func updateUIViewController(_ uiViewController: OnboardingViewController, context: Context) {
        if uiViewController.pageIndicator.currentPage != selectedSlide {
            uiViewController.setSelectedSlide(index: selectedSlide)
        }

        let coordinator = context.coordinator

        guard coordinator.currentAccentColor != accentColor
            || coordinator.currentColorScheme != context.environment.colorScheme
        else { return }
        coordinator.invalidateColors()

        let newColorScheme = context.environment.colorScheme
        coordinator.currentAccentColor = accentColor
        coordinator.currentColorScheme = newColorScheme

        uiViewController.currentSlideViewCell?.backgroundImageView.tintColor = newColorScheme == .dark ? MailResourcesAsset
            .backgroundSecondaryColor.color : accentColor.secondary.color
        uiViewController.pageIndicator.currentPageIndicatorTintColor = accentColor.primary.color

        guard let illustrationAnimationViewContent = uiViewController.currentSlideViewCell?.illustrationAnimationViewContent
        else {
            return
        }

        switch illustrationAnimationViewContent {
        case .airbnbLottieAnimationView(_, let ikLottieConfiguration):
            uiViewController.currentSlideViewCell?.updateAnimationColors(configuration: ikLottieConfiguration)
        case .dotLottieAnimationView(let dotLottieAnimationView, _):
            uiViewController.currentSlideViewCell?.setThemeFor(
                colorScheme: newColorScheme,
                accentColor: accentColor,
                dotLottieViewModel: dotLottieAnimationView.dotLottieViewModel
            )
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(
            selectedSlide: $selectedSlide,
            slides: slides,
            shouldAnimateBottomViewForIndex: shouldAnimateBottomViewForIndex,
            bottomView: bottomView
        )
    }

    class Coordinator: OnboardingViewControllerDelegate {
        var currentAccentColor: AccentColor?
        var currentColorScheme: ColorScheme?

        let selectedSlide: Binding<Int>
        let slides: [Slide]
        var colorUpdateNeededAtIndex = Set<Int>()

        let shouldAnimateBottomViewForIndex: (Int) -> Bool
        let bottomView: (Int) -> BottomView

        init(
            selectedSlide: Binding<Int>,
            slides: [Slide],
            shouldAnimateBottomViewForIndex: @escaping (Int) -> Bool,
            bottomView: @escaping (Int) -> BottomView
        ) {
            self.selectedSlide = selectedSlide
            self.slides = slides
            self.shouldAnimateBottomViewForIndex = shouldAnimateBottomViewForIndex
            self.bottomView = bottomView
        }

        func bottomViewForIndex(_ index: Int) -> (any View)? {
            return bottomView(index)
        }

        func shouldAnimateBottomViewForIndex(_ index: Int) -> Bool {
            return shouldAnimateBottomViewForIndex(index)
        }

        func willDisplaySlideViewCell(_ slideViewCell: SlideCollectionViewCell, at index: Int) {
            slideViewCell.backgroundImageView.tintColor = slideViewCell.traitCollection.userInterfaceStyle == .dark ?
                MailResourcesAsset.backgroundSecondaryColor.color :
                UserDefaults.shared.accentColor.secondary.color

            if case .animation(let configuration) = slides[index].content,
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
