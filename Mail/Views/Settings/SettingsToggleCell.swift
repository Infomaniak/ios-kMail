/*
 Infomaniak Mail - iOS App
 Copyright (C) 2022 Infomaniak Network SA

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
import MailResources
import SwiftUI

struct SettingsToggleCell: View {
    @LazyInjectService private var appLockHelper: AppLockHelper

    let title: String
    let userDefaults: ReferenceWritableKeyPath<UserDefaults, Bool>

    let matomoCategory: MatomoUtils.EventCategory?
    let matomoName: String?

    @State private var toggleIsOn: Bool {
        didSet {
            UserDefaults.shared[keyPath: userDefaults] = toggleIsOn

            // AppStorage updates the views only if directly called
            if userDefaults == \.isAppLockEnabled {
                AppStorage(UserDefaults.shared.key(.appLock)).wrappedValue = UserDefaults.shared.isAppLockEnabled
                if UserDefaults.shared.isAppLockEnabled {
                    appLockHelper.setTime()
                }
            }
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
                @InjectService var matomo: MatomoUtils
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
        .settingsItem()
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

#Preview {
    SettingsToggleCell(title: "Code lock", userDefaults: \.isAppLockEnabled)
}
