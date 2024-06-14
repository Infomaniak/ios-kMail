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

import CocoaLumberjackSwift
import InfomaniakCoreUI
import MailCore
import MailCoreUI
import MailResources
import RealmSwift
import SwiftUI

struct MailboxSignatureSettingsView: View {
    @ObservedResults(Signature.self) var signatures

    let mailboxManager: MailboxManager

    init(mailboxManager: MailboxManager) {
        self.mailboxManager = mailboxManager
        _signatures = ObservedResults(Signature.self, configuration: mailboxManager.realmConfiguration)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            List {
                SettingsSectionTitleView(title: MailResourcesStrings.Localizable.settingsSignatureDescription)
                    .settingsCell()

                SettingsOptionCell(
                    title: MailResourcesStrings.Localizable.selectSignatureNone,
                    isSelected: signatures.defaultSignature == nil,
                    isLast: false
                ) {
                    setAsDefault(nil)
                }

                ForEach(signatures) { signature in
                    SettingsOptionCell(
                        title: signature.name,
                        isSelected: signature.isDefault,
                        isLast: signature == signatures.last
                    ) {
                        setAsDefault(signature)
                    }
                }
                .settingsCell()
            }
            .listStyle(.plain)
        }
        .background(MailResourcesAsset.backgroundColor.swiftUIColor)
        .navigationTitle(MailResourcesStrings.Localizable.settingsSignatureTitle)
        .navigationBarTitleDisplayMode(.inline)
        .backButtonDisplayMode(.minimal)
        .matomoView(view: [MatomoUtils.View.settingsView.displayName, "Signatures"])
        .task {
            do {
                try await mailboxManager.refreshAllSignatures()
            } catch {
                DDLogError("Error fetching signatures: \(error.localizedDescription)")
            }
        }
    }

    private func setAsDefault(_ signature: Signature?) {
        guard signature?.isDefault != true else { return }

        let detachedSignature = signature?.detached()
        detachedSignature?.isDefault = true

        Task {
            try await mailboxManager.updateSignature(signature: detachedSignature)
        }
    }
}

#Preview {
    MailboxSignatureSettingsView(mailboxManager: PreviewHelper.sampleMailboxManager)
}
