/*
 Infomaniak Mail - iOS App
 Copyright (C) 2025 Infomaniak Network SA

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

import DesignSystem
import MailCoreUI
import MailResources
import SwiftUI

struct EncryptionAdView: View {
    @Environment(\.dismiss) private var dismiss

    let enableEncryption: () -> Void

    var body: some View {
        NavigationView {
            VStack(spacing: IKPadding.huge) {
                MailResourcesAsset.encryptEnvelop.swiftUIImage

                Text(MailResourcesStrings.Localizable.encryptedProtectionAdDescription)
                    .textStyle(.body)

                VStack(alignment: .leading, spacing: IKPadding.medium) {
                    Text("• \(MailResourcesStrings.Localizable.encryptedProtectionAdDescription1)")
                        .textStyle(.body)

                    Text("• \(MailResourcesStrings.Localizable.encryptedProtectionAdDescription2)")
                        .textStyle(.body)

                    Button {
                        // En savoir plus
                    } label: {
                        Text(MailResourcesStrings.Localizable.moreInfo)
                    }
                }

                VStack(spacing: IKPadding.large) {
                    Button {
                        enableEncryption()
                        dismiss()
                    } label: {
                        Text(MailResourcesStrings.Localizable.buttonActivate)
                    }
                    .buttonStyle(.ikBorderedProminent)

                    Button {
                        dismiss()
                    } label: {
                        Text(MailResourcesStrings.Localizable.buttonLater)
                    }
                }
                .ikButtonFullWidth(true)
                .controlSize(.large)
                .frame(maxHeight: .infinity, alignment: .bottom)
            }
            .padding(.vertical, value: .large)
            .padding(.horizontal, value: .medium)
            .frame(maxHeight: .infinity, alignment: .top)
            .navigationTitle(MailResourcesStrings.Localizable.encryptedProtectionAdTitle)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    EncryptionAdView {}
}
