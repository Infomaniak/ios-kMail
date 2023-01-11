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

import Introspect
import Lottie
import MailCore
import MailResources
import SwiftUI

struct SlideView: View {
    let slide: Slide

    @AppStorage(UserDefaults.shared.key(.accentColor), store: .shared) private var accentColor = AccentColor.pink

    @Environment(\.window) private var window
    @Environment(\.colorScheme) private var colorScheme

    @State private var segmentedControl: UISegmentedControl?
    @State private var imageSize: CGSize = .zero

    @State private var isVisible = false

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .top) {
                slide.backgroundImage
                    .resizable()
                    .frame(height: proxy.size.height * 0.62)
                    .foregroundColor(colorScheme == .light ? accentColor.secondary : MailResourcesAsset.backgroundColor)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer(minLength: Constants.onboardingLogoHeight + Constants.onboardingVerticalTopPadding)

                    LottieView(
                        isVisible: $isVisible,
                        filename: slide.animationFile,
                        configuration: slide.lottieConfiguration,
                        updateColors: updateAnimationColors
                    )
                    .frame(height: 0.43 * proxy.size.height)

                    Spacer(minLength: 8)

                    Text(slide.title)
                        .textStyle(.header2)

                    if slide.id == 1 {
                        Picker("Accent color", selection: $accentColor) {
                            ForEach(AccentColor.allCases, id: \.rawValue) { color in
                                Text(color.title)
                                    .tag(color)
                            }
                        }
                        .pickerStyle(.segmented)
                        .introspectSegmentedControl { segmentedControl in
                            self.segmentedControl = segmentedControl
                            setSegmentedControlStyle()
                        }
                        .padding(.top, 32)
                        .frame(maxWidth: 256)
                    } else {
                        Text(slide.description)
                            .textStyle(.bodySecondary)
                            .padding(.top, 24)
                    }

                    Spacer(minLength: 48)
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            }
            .onChange(of: accentColor) { _ in
                // Handle accent color change
                (window?.windowScene?.delegate as? SceneDelegate)?.updateWindowUI()
                setSegmentedControlStyle()
            }
            .onAppear {
                isVisible = true
            }
            .onDisappear {
                isVisible = false
            }
        }
    }

    private func setSegmentedControlStyle() {
        segmentedControl?.selectedSegmentTintColor = .tintColor
        segmentedControl?.setTitleTextAttributes([.foregroundColor: MailResourcesAsset.onAccentColor.color], for: .selected)
        let nonAccentColor: AccentColor = accentColor == .pink ? .blue : .pink
        segmentedControl?.setTitleTextAttributes([.foregroundColor: nonAccentColor.primary.color], for: .normal)
        segmentedControl?.backgroundColor = nonAccentColor.secondary.color
    }

    private func updateAnimationColors(_ animation: LottieAnimationView, _ configuration: LottieConfiguration) {
        IlluColors.allColors.forEach { $0.applyColors(to: animation) }

        if configuration.id == 2 || configuration.id == 3 || configuration.id == 4 {
            IlluColors.illu234Colors.forEach { $0.applyColors(to: animation) }
        }

        switch configuration.id {
        case 1:
            IlluColors.illu1Colors.forEach { $0.applyColors(to: animation) }
        case 2:
            IlluColors.illu2Colors.forEach { $0.applyColors(to: animation) }
        case 3:
            IlluColors.illu3Colors.forEach { $0.applyColors(to: animation) }
        case 4:
            IlluColors.illu4Colors.forEach { $0.applyColors(to: animation) }
        default:
            break
        }

        if UserDefaults.shared.accentColor == .pink {
            IlluColors.pinkColors.forEach { $0.applyColors(to: animation) }

            if configuration.id == 2 || configuration.id == 3 || configuration.id == 4 {
                IlluColors.illu234PinkColors.forEach { $0.applyColors(to: animation) }
            }

            switch configuration.id {
            case 1:
                IlluColors.illu1PinkColors.forEach { $0.applyColors(to: animation) }
            case 2:
                IlluColors.illu2PinkColors.forEach { $0.applyColors(to: animation) }
            case 3:
                IlluColors.illu3PinkColors.forEach { $0.applyColors(to: animation) }
            case 4:
                IlluColors.illu4PinkColors.forEach { $0.applyColors(to: animation) }
            default:
                break
            }
        } else {
            IlluColors.blueColors.forEach { $0.applyColors(to: animation) }

            if configuration.id == 2 || configuration.id == 3 || configuration.id == 4 {
                IlluColors.illu234BlueColors.forEach { $0.applyColors(to: animation) }
            }

            switch configuration.id {
            case 1:
                IlluColors.illu1BlueColors.forEach { $0.applyColors(to: animation) }
            case 2:
                IlluColors.illu2BlueColors.forEach { $0.applyColors(to: animation) }
            case 3:
                IlluColors.illu3BlueColors.forEach { $0.applyColors(to: animation) }
            case 4:
                IlluColors.illu4BlueColors.forEach { $0.applyColors(to: animation) }
            default:
                break
            }
        }
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
        SlideView(slide: Slide.allSlides[0])
    }
}
