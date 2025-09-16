/*
 Infomaniak Mail - iOS App
 Copyright (C) 2023 Infomaniak Network SA

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
import InfomaniakCoreSwiftUI
import InfomaniakDI
import MailCore
import MailCoreUI
import NavigationBackport
import SwiftUI

struct SettingsNavigationView: View {
    @InjectService private var platformDetector: PlatformDetectable

    @Environment(\.dismiss) private var dismiss

    @State private var navigationPath: [SettingsDestination]

    init(baseNavigationPath: [SettingsDestination]) {
        _navigationPath = State(wrappedValue: baseNavigationPath)
    }

    var body: some View {
        if #available(iOS 16.0, *) {
            NavigationStack(path: $navigationPath) {
                SettingsView()
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            if !platformDetector.isMac || platformDetector.isLegacyMacCatalyst {
                                ToolbarCloseButton(dismissAction: dismiss)
                            }
                        }
                    }
                    .navigationDestination(for: SettingsDestination.self) { _ in
                        SettingsNotificationsView()
                    }
            }
            .environment(\.dismissModal) {
                dismiss()
            }
        } else {
            NBNavigationStack(path: $navigationPath) {
                SettingsView()
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            if !platformDetector.isMac || platformDetector.isLegacyMacCatalyst {
                                ToolbarCloseButton(dismissAction: dismiss)
                            }
                        }
                    }
                    .nbNavigationDestination(for: SettingsDestination.self) { _ in
                        SettingsNotificationsView()
                    }
            }
            .environment(\.dismissModal) {
                dismiss()
            }
        }
    }
}

#Preview {
    SettingsNavigationView(baseNavigationPath: [])
        .environment(\.currentUser, MandatoryEnvironmentContainer(value: PreviewHelper.sampleUser))
}
