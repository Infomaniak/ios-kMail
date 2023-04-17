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

import InfomaniakCore
import InfomaniakCoreUI
import InfomaniakDI
import Introspect
import Lottie
import MailCore
import MailResources
import SwiftUI

struct SlideView: View {
    let slide: Slide
    var updateAnimationColors: LottieView.UpdateColorsClosure?

    @LazyInjectService private var matomo: MatomoUtils

    @AppStorage(UserDefaults.shared.key(.accentColor)) private var accentColor = DefaultPreferences.accentColor

    @Environment(\.window) private var window
    @Environment(\.colorScheme) private var colorScheme

    @State private var isVisible = false

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .top) {
                slide.backgroundImage
                    .resizable()
                    .frame(height: proxy.size.height * 0.62)
                    .foregroundColor(colorScheme == .light ? accentColor.secondary : MailResourcesAsset.backgroundSecondaryColor)
                    .ignoresSafeArea(edges: .top)

                VStack(spacing: 0) {
                    Spacer(minLength: UIConstants.onboardingLogoHeight + UIConstants.onboardingVerticalTopPadding)

                    Group {
                        if let asset = slide.asset {
                            asset
                                .resizable()
                                .scaledToFit()
                        } else if let lottieConfiguration = slide.lottieConfiguration {
                            LottieView(
                                configuration: lottieConfiguration,
                                isVisible: $isVisible,
                                updateColors: updateAnimationColors
                            )
                        }
                    }
                    .frame(height: 0.43 * proxy.size.height)

                    Spacer(minLength: 8)

                    Text(slide.title)
                        .textStyle(.header2)

                    if slide.showPicker {
                        Picker("Accent color", selection: $accentColor) {
                            ForEach(AccentColor.allCases, id: \.rawValue) { color in
                                Text(color.title)
                                    .tag(color)
                            }
                        }
                        .pickerStyle(.segmented)
                        .introspectSegmentedControl { segmentedControl in
                            setSegmentedControlStyle(segmentedControl)
                        }
                        .padding(.top, 32)
                        .frame(maxWidth: 256)
                        .onChange(of: accentColor) { newValue in
                            matomo.track(eventWithCategory: .onboarding, name: "switchColor", value: newValue == .blue)
                        }
                    } else if let description = slide.description {
                        Text(description)
                            .textStyle(.bodySecondary)
                            .padding(.top, 24)
                    }

                    Spacer(minLength: 48)
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            }
            .onChange(of: accentColor) { _ in
                (window?.windowScene?.delegate as? SceneDelegate)?.updateWindowUI()
            }
            .onAppear {
                isVisible = true
            }
            .onDisappear {
                isVisible = false
            }
        }
    }

    private func setSegmentedControlStyle(_ segmentedControl: UISegmentedControl) {
        segmentedControl.selectedSegmentTintColor = .tintColor
        segmentedControl.setTitleTextAttributes([.foregroundColor: accentColor.onAccent.color], for: .selected)
        let nonAccentColor: AccentColor = accentColor == .pink ? .blue : .pink
        segmentedControl.setTitleTextAttributes([.foregroundColor: nonAccentColor.primary.color], for: .normal)
        segmentedControl.backgroundColor = nonAccentColor.secondary.color
    }
}

struct SlideView_Previews: PreviewProvider {
    static var previews: some View {
        slideView
            .previewDevice(PreviewDevice(rawValue: "iPhone 14 Pro"))
            .previewDisplayName("Large Screen")

        slideView
            .previewDevice(PreviewDevice(rawValue: "iPhone SE (3rd generation)"))
            .previewDisplayName("Small Screen")
    }

    static var slideView: some View {
        SlideView(slide: Slide.onBoardingSlides[0]) { _, _ in /* Preview */ }
    }
}
