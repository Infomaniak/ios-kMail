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

struct LockedAppView: View {
    @Environment(\.window) var window

    var body: some View {
        ZStack {
            VStack(spacing: 27) {
                Image(resource: MailResourcesAsset.lock)
                    .frame(width: 187, height: 187)

                Text(MailResourcesStrings.Localizable.lockAppTitle)
                    .textStyle(.header2)
            }

            VStack {
                Image(resource: MailResourcesAsset.logoText)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 214)

                Spacer()

                LargeButton(title: MailResourcesStrings.Localizable.buttonUnlock, action: unlockApp)
            }
            .padding(.top, 30)
            .padding(.bottom, 40)
        }
        .defaultAppStorage(.shared)
        .onAppear {
            unlockApp()
        }
    }

    private func unlockApp() {
        Task {
            if (try? await AppLockHelper.shared.evaluatePolicy(reason: MailResourcesStrings.Localizable.lockAppTitle)) == true {
                await (window?.windowScene?.delegate as? SceneDelegate)?.showMainView()
            }
        }
    }
}

struct LockedAppView_Previews: PreviewProvider {
    static var previews: some View {
        LockedAppView()
    }
}
