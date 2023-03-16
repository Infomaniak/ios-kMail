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
import MailCore
import MailResources
import SwiftUI

struct SettingsToggleCell: View {
    @LazyInjectService var appLockHelper: AppLockHelper
    @LazyInjectService var matomo: MatomoUtils

    let title: String
    let userDefaults: ReferenceWritableKeyPath<UserDefaults, Bool>

    let matomoCategory: MatomoUtils.EventCategory?
    let matomoName: String?

    @State private var toggleIsOn: Bool {
        didSet {
            UserDefaults.shared[keyPath: userDefaults] = toggleIsOn
        }
    }

    @State private var lastValue: Bool

    init(
        title: String,
        userDefaults: ReferenceWritableKeyPath<UserDefaults, Bool>,
        matomoCategory: MatomoUtils.EventCategory? = nil,
        matomoName: String? = nil
    ) {
        self.title = title
        self.userDefaults = userDefaults
        _toggleIsOn = State(wrappedValue: UserDefaults.shared[keyPath: userDefaults])
        _lastValue = _toggleIsOn
        self.matomoCategory = matomoCategory
        self.matomoName = matomoName
    }

    var body: some View {
        Toggle(isOn: Binding(get: {
            toggleIsOn
        }, set: { newValue in
            lastValue = toggleIsOn
            toggleIsOn = newValue
            if let matomoCategory, let matomoName {
                matomo.track(eventWithCategory: matomoCategory, name: matomoName, value: newValue)
            }
        })) {
            Text(title)
                .textStyle(.body)
        }
        .tint(.accentColor)
        .onChange(of: toggleIsOn) { newValue in
            guard newValue != lastValue else { return }
            if userDefaults == \.isAppLockEnabled {
                enableAppLock()
            }
        }
    }

    private func enableAppLock() {
        Task {
            do {
                if try await !appLockHelper.evaluatePolicy(reason: MailResourcesStrings.Localizable.appSecurityDescription) {
                    withAnimation {
                        toggleIsOn.toggle()
                    }
                }
            } catch {
                withAnimation {
                    toggleIsOn.toggle()
                }
            }
        }
    }
}

struct SettingsToggleCell_Previews: PreviewProvider {
    static var previews: some View {
        SettingsToggleCell(title: "Code lock", userDefaults: \.isAppLockEnabled)
    }
}
