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

import NavigationBackport
import SwiftUI

enum SyncProfileStep {
    case downloadProfile
    case copyPassword
    case installProfile
}

struct SyncProfileNavigationView: View {
    @State private var navigationPath: [SyncProfileStep] = []

    var body: some View {
        NBNavigationStack(path: $navigationPath) {
            SyncWelcomeView()
                .nbNavigationDestination(for: SyncProfileStep.self) { step in
                    switch step {
                    case .downloadProfile:
                        SyncDownloadProfileView()
                    case .copyPassword:
                        SyncCopyPasswordView()
                    case .installProfile:
                        SyncInstallProfileTutorialView()
                    }
                }
        }
        .nbUseNavigationStack(.whenAvailable)
    }
}

#Preview {
    SyncProfileNavigationView()
}
