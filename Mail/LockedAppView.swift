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

// TODO: Update the view when the mock-up is ready (current view based on kDrive)

struct LockedAppView: View {
    @Environment(\.window) var window

    var body: some View {
        VStack {
            Image(resource: MailResourcesAsset.logoText)
                .resizable()
                .scaledToFit()
                .frame(width: 200)

            Spacer()

            Circle()
                .frame(width: 175, height: 175)
                .foregroundColor(MailResourcesAsset.backgroundHeaderColor)
                .overlay {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.accentColor)
                }
                .padding(.bottom, 5)
            Text(MailResourcesStrings.lockAppTitle)
                .font(.body)

            Spacer()

            Button(action: unlockApp) {
                Text(MailResourcesStrings.buttonUnlock)
                    .frame(maxWidth: .infinity)
                    .padding([.top, .bottom])
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
            }
            .padding([.leading, .trailing], 40)
        }
        .padding(.top, 20)
        .padding(.bottom, 75)
    }

    private func unlockApp() {
        Task {
            if (try? await AppLockHelper.shared.evaluatePolicy(reason: MailResourcesStrings.lockAppTitle)) == true {
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
