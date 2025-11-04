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

import InfomaniakCore
import InfomaniakCoreCommonUI
import InfomaniakDI
import MailCore
import MailCoreUI
import SwiftUI

struct OnboardingThemePickerView: View {
    @AppStorage(UserDefaults.shared.key(.accentColor)) private var accentColor = DefaultPreferences.accentColor

    let title: String

    var body: some View {
        VStack(spacing: 0) {
            Text(title)
                .textStyle(.header2)
            Picker("Accent color", selection: $accentColor) {
                ForEach(AccentColor.allCases, id: \.rawValue) { color in
                    Text(color.title)
                        .tag(color)
                }
            }
            .pickerStyle(.segmented)
            .introspect(.picker(style: .segmented), on: .iOS(.v15, .v16, .v17, .v18, .v26)) { segmentedControl in
                setSegmentedControlStyle(segmentedControl)
            }
            .padding(.top, value: .huge)
            .frame(maxWidth: 256)
            .onChange(of: accentColor) { newValue in
                @InjectService var matomo: MatomoUtils
                matomo.track(eventWithCategory: .onboarding, name: "switchColor\(newValue.rawValue.capitalized)")
            }
        }
        .multilineTextAlignment(.center)
    }

    private func setSegmentedControlStyle(_ segmentedControl: UISegmentedControl) {
        segmentedControl.selectedSegmentTintColor = .tintColor
        segmentedControl.setTitleTextAttributes([.foregroundColor: accentColor.onAccent.color], for: .selected)
        let nonAccentColor: AccentColor = accentColor == .pink ? .blue : .pink
        segmentedControl.setTitleTextAttributes([.foregroundColor: nonAccentColor.primary.color], for: .normal)
        segmentedControl.backgroundColor = nonAccentColor.secondary.color
    }
}

#Preview {
    OnboardingThemePickerView(title: "Picker")
}
