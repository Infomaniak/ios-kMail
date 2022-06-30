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
import MailResources
import SwiftUI

struct SettingsToggleCell: View {
    let title: String
    let userDefaults: ReferenceWritableKeyPath<UserDefaults, Bool>

    @State private var toggleIsOn: Bool
    @State private var lastValue: Bool

    init(title: String, userDefaults: ReferenceWritableKeyPath<UserDefaults, Bool>) {
        self.title = title
        self.userDefaults = userDefaults
        _toggleIsOn = State(wrappedValue: UserDefaults.shared[keyPath: userDefaults])
        _lastValue = _toggleIsOn
    }

    var body: some View {
        Toggle(isOn: Binding(get: {
            toggleIsOn
        }, set: { value in
            lastValue = toggleIsOn
            toggleIsOn = value
            UserDefaults.shared[keyPath: userDefaults] = value
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
                     if try await !AppLockHelper.shared.evaluatePolicy(reason: MailResourcesStrings.Localizable.appSecurityDescription) {
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
