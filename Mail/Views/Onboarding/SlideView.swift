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

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .top) {
                slide.backgroundImage
                    .resizable()
                    .frame(width: proxy.size.width, height: proxy.size.width, alignment: .top)
                    .foregroundColor(colorScheme == .light ? accentColor.secondary : MailResourcesAsset.backgroundColor)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer(minLength: Constants.onboardingLogoHeight + Constants.onboardingVerticalPadding)

                    LottieView(filename: slide.animationFile)
                        .frame(maxHeight: 250)

                    Spacer(minLength: 28)

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
                        .padding(.horizontal, 32)
                        .frame(maxWidth: 350)
                    } else {
                        Text(slide.description)
                            .textStyle(.bodySecondary)
                            .padding(.top, 24)
                    }

                    Spacer()
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            }
        }
        .onChange(of: accentColor) { _ in
            // Handle accent color change
            (window?.windowScene?.delegate as? SceneDelegate)?.updateWindowUI()
            setSegmentedControlStyle()
        }
    }

    private func setSegmentedControlStyle() {
        segmentedControl?.selectedSegmentTintColor = .tintColor
        segmentedControl?.setTitleTextAttributes([.foregroundColor: MailResourcesAsset.onAccentColor.color], for: .selected)
        let nonAccentColor: AccentColor = accentColor == .pink ? .blue : .pink
        segmentedControl?.setTitleTextAttributes([.foregroundColor: nonAccentColor.primary.color], for: .normal)
        segmentedControl?.backgroundColor = nonAccentColor.secondary.color
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
        SlideView(slide: Slide(
            id: 1,
            backgroundImage: Image(resource: MailResourcesAsset.onboardingBackground1),
            animationFile: "illu_1",
            title: "Title",
            description: "Description"
        ))
    }
}
