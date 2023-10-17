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

import MailCore
import MailResources
import SwiftUI
import VersionChecker

struct UpdateAvailableView: View {
    @Environment(\.openURL) private var openURL
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 32) {
            MailResourcesAsset.logoMailWithStar.swiftUIImage
                .resizable()
                .frame(width: 98, height: 98)

            Text(MailResourcesStrings.Localizable.updateAvailableTitle)
                .textStyle(.header2)

            Text(MailResourcesStrings.Localizable.updateAvailableDescription)
                .textStyle(.bodySecondary)
                .multilineTextAlignment(.center)

            MailButton(label: MailResourcesStrings.Localizable.buttonUpdate) {
                dismiss()
                let url: URLConstants = Bundle.main.isRunningInTestFlight ?
                    .testFlight : .appStore
                openURL(url.url)
            }
            .mailButtonFullWidth(true)

            MailButton(label: MailResourcesStrings.Localizable.buttonLater) {
                VersionChecker.standard.updateLater()
                dismiss()
            }
            .mailButtonStyle(.link)
        }
        .padding(.horizontal, 24)
    }
}

#Preview {
    UpdateAvailableView()
}
