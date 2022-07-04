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
import SwiftUI

struct SlideView: View {
    let slide: Slide

    @AppStorage(UserDefaults.shared.key(.accentColor), store: .shared) private var accentColor = AccentColor.pink

    @Environment(\.window) private var window

    @State var orientation: UIInterfaceOrientation?
    @State var segmentedControl: UISegmentedControl?

    var body: some View {
        ZStack(alignment: .top) {
            accentColor.secondary.swiftUiColor
                .frame(maxHeight: 427)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                if orientation?.isPortrait == true {
                    slide.illustrationImage
                        .resizable()
                        .scaledToFit()
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
                    .padding(.horizontal, 32)
                } else {
                    Text(slide.description)
                        .textStyle(.bodySecondary)
                }
            }
            .multilineTextAlignment(.center)
            .padding(.top, 96)
            .padding(.horizontal, 40)
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .onChange(of: accentColor) { _ in
            // Handle accent color change
            (window?.windowScene?.delegate as? SceneDelegate)?.updateWindowUI()
            setSegmentedControlStyle()
        }
        .onAppear {
            orientation = window?.windowScene?.interfaceOrientation
        }
        .onRotate { orientation in
            self.orientation = orientation
        }
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
                               backgroundImage: Image(""),
                               illustrationImage: Image(""),
                               title: "Title",
                               description: "Description"))
    }
}
