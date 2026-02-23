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

import MailCoreUI
import SwiftUI

enum SyncProfileStep {
    case downloadProfile
    case copyPassword
    case installProfile
}

struct SyncProfileNavigationView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var navigationPath: [SyncProfileStep] = []

    var body: some View {
        NavigationStack(path: $navigationPath) {
            SyncWelcomeView(navigationPath: $navigationPath)
                .navigationDestination(for: SyncProfileStep.self) { step in
                    Group {
                        switch step {
                        case .downloadProfile:
                            SyncDownloadProfileView(navigationPath: $navigationPath)
                        case .copyPassword:
                            SyncCopyPasswordView(navigationPath: $navigationPath)
                        case .installProfile:
                            SyncInstallProfileTutorialView()
                        }
                    }
                    .backButtonDisplayMode(.minimal)
                    .navigationBarTitleDisplayMode(.inline)
                    .environment(\.dismissModal) { dismiss() }
                }
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        ToolbarCloseButton(dismissAction: dismiss)
                    }
                }
                .backButtonDisplayMode(.minimal)
        }
    }
}

#Preview {
    SyncProfileNavigationView()
}
