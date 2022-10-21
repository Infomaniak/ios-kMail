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

    @State var segmentedControl: UISegmentedControl?
    @State var imageSize: CGSize = .zero

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .top) {
                slide.backgroundImage
                    .resizable(resizingMode: .stretch)
                    .ignoresSafeArea()
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundColor(colorScheme == .light ? accentColor.secondary : MailResourcesAsset.backgroundColor)

                VStack(spacing: 0) {
                    Spacer(minLength: Constants.onboardingLogoHeight + Constants.onboardingVerticalPadding)

                    if proxy.size.height > 500, let illustrationImage = illustrationImage(for: slide) {
                        illustrationImage
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 400, maxHeight: 400)
                            .aspectRatio(1, contentMode: .fit)
                        Spacer()
                    }

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
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .onChange(of: accentColor) { _ in
            // Handle accent color change
            (window?.windowScene?.delegate as? SceneDelegate)?.updateWindowUI()
            setSegmentedControlStyle()
        }
    }

    private func illustrationImage(for slide: Slide) -> Image? {
        let resource: MailResourcesImages?
        switch slide.id {
        case 1:
            resource = accentColor.onboardingIllu1
        case 2:
            resource = accentColor.onboardingIllu2
        case 3:
            resource = accentColor.onboardingIllu3
        case 4:
            resource = accentColor.onboardingIllu4
        default:
            resource = nil
        }

        if let resource = resource {
            return Image(resource: resource)
        }
        return nil
    }

    private func setSegmentedControlStyle() {
        segmentedControl?.selectedSegmentTintColor = .tintColor
        segmentedControl?.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        let nonAccentColor: AccentColor = accentColor == .pink ? .blue : .pink
        segmentedControl?.setTitleTextAttributes([.foregroundColor: nonAccentColor.primary.color], for: .normal)
        segmentedControl?.backgroundColor = nonAccentColor.secondary.color
    }
}

struct SlideView_Previews: PreviewProvider {
    static var previews: some View {
        SlideView(slide: Slide(id: 1,
                               backgroundImage: Image(resource: MailResourcesAsset.onboardingBackground1),
                               title: "Title",
                               description: "Description"))
    }
}
