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

import InfomaniakCoreUI
import MailCore
import MailResources
import RealmSwift
import SwiftUI

struct MailboxSignatureSettingsView: View {
    @EnvironmentObject var mailboxManager: MailboxManager
    @ObservedResults(SignatureResponse.self) var signatureResponse

    var body: some View {
        List {
            Section {
                ForEach(signatureResponse.first?.signatures.toArray() ?? []) { signature in
                    Button {
                        setAsDefault(signature)
                    } label: {
                        VStack(spacing: 0) {
                            HStack(spacing: 16) {
                                MailResourcesAsset.signature.swiftUIImage
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 24, height: 24)
                                    .foregroundColor(MailResourcesAsset.textTertiaryColor)
                                Text(signature.name)
                                    .textStyle(.body)
                                Spacer()
                                if signature.isDefault {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                            .padding(.vertical, 16)
                            .padding(.horizontal, 24)

                            if signature != signatureResponse.first?.signatures.last {
                                IKDivider()
                                    .padding(.horizontal, 8)
                            }
                        }
                    }
                }
                .listRowSeparator(.hidden)
                .listRowInsets(.init())
                .background(MailResourcesAsset.backgroundColor.swiftUIColor)
            }
        }
        .listStyle(.plain)
        .navigationTitle(MailResourcesStrings.Localizable.settingsSignatureTitle)
        .navigationBarTitleDisplayMode(.inline)
        .backButtonDisplayMode(.minimal)
        .matomoView(view: [MatomoUtils.View.settingsView.displayName, "Signatures"])
    }

    private func setAsDefault(_ signature: Signature) {
        guard !signature.isDefault else { return }
        let detachedSignature = signature.detached()
        detachedSignature.isDefault = true
        Task {
            try await mailboxManager.updateSignature(signature: detachedSignature)
        }
    }
}

struct MailboxSignatureSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        MailboxSignatureSettingsView()
    }
}
