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

import InfomaniakCoreCommonUI
import InfomaniakDI
import MailCore
import MailCoreUI
import MailResources
import OSLog
import RealmSwift
import SwiftUI

struct MailboxSignatureSettingsView: View {
    @State private var isShowingMyKSuiteUpgrade = false

    @ObservedResults(Signature.self) private var signatures

    let mailboxManager: MailboxManager

    private var isKSuiteLimited: Bool {
        signatures.defaultSignature != nil && mailboxManager.mailbox.pack == .myKSuiteFree
    }

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
                    if isKSuiteLimited {
                        isShowingMyKSuiteUpgrade = true
                        @InjectService var matomo: MatomoUtils
                        matomo.track(eventWithCategory: .myKSuiteUpgradeBottomSheet, name: "emptySignature")
                    } else {
                        setAsDefault(nil)
                    }
                } trailingView: {
                    if isKSuiteLimited {
                        MyKSuitePlusChip()
                    }
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
        .mailMyKSuiteFloatingPanel(isPresented: $isShowingMyKSuiteUpgrade, configuration: .mail)
        .task {
            do {
                try await mailboxManager.refreshAllSignatures()
            } catch {
                Logger.view.error("Error fetching signatures: \(error.localizedDescription)")
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
