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

import MailResources
import SwiftUI

struct OnboardingView: View {
    @StateObject var viewModel = OnboardingViewModel()
    @State private var selection = 1

    init() {
        UIPageControl.appearance().currentPageIndicatorTintColor = .tintColor
        UIPageControl.appearance().pageIndicatorTintColor = MailResourcesAsset.separatorColor.color
    }

    var body: some View {
        VStack(spacing: 16) {
            // Slides
            ZStack(alignment: .top) {
                TabView(selection: $selection) {
                    ForEach(viewModel.slides) { slide in
                        SlideView(slide: slide)
                            .tag(slide.id)
                    }
                }
                .tabViewStyle(.page)
                .ignoresSafeArea()

                Image(resource: MailResourcesAsset.logoText)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 72)
            }

            // Buttons
            VStack(spacing: 24) {
                if selection == viewModel.slides.count {
                    // Show login button
                    LargeButton(title: MailResourcesStrings.Localizable.buttonLogin) {
                        // TODO: Login
                    }
                    Button {
                        // TODO: Create account
                    } label: {
                        Text(MailResourcesStrings.Localizable.buttonCreateAccount)
                            .textStyle(.button)
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
            .frame(height: 140, alignment: .top)
        }
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
    }
}
