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
import InfomaniakDI
import MailCore
import MailResources
import SwiftUI

struct AIDiscoveryView: View {
    @LazyInjectService private var matomo: MatomoUtils

    @Environment(\.isCompactWindow) private var isCompactWindow
    @Environment(\.dismiss) private var dismiss

    @State private var willShowAIPrompt = false

    @ObservedObject var aiModel: AIModel

    var body: some View {
        Group {
            if isCompactWindow {
                AIDiscoveryBottomSheetView(tryButton: didTouchTryButton, laterButton: didTouchLaterButton)
            } else {
                AIDiscoveryAlertView(tryButton: didTouchTryButton, laterButton: didTouchLaterButton)
            }
        }
        .onAppear {
            UserDefaults.shared.shouldPresentAIFeature = false
        }
        .onDisappear {
            if willShowAIPrompt {
                aiModel.isShowingPrompt = true
            } else {
                matomo.track(eventWithCategory: .aiWriter, name: "discoverLater")
            }
        }
    }

    private func didTouchTryButton() {
        matomo.track(eventWithCategory: .aiWriter, name: "discoverTry")
        willShowAIPrompt = true
        dismiss()
    }

    private func didTouchLaterButton() {
        dismiss()
    }
}

struct AIDiscoveryBottomSheetView: View {
    let tryButton: () -> Void
    let laterButton: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            MailResourcesAsset.aiIllustration.swiftUIImage

            Text(MailResourcesStrings.Localizable.aiDiscoveryTitle)
                .textStyle(.header2)

            Text(MailResourcesStrings.Localizable.aiDiscoveryDescription)
                .multilineTextAlignment(.center)
                .textStyle(.bodySecondary)

            VStack(spacing: UIPadding.medium) {
                MailButton(label: MailResourcesStrings.Localizable.buttonTry, action: tryButton)
                    .mailButtonFullWidth(true)

                MailButton(label: MailResourcesStrings.Localizable.buttonLater, action: laterButton)
                    .mailButtonStyle(.link)
            }
        }
        .padding(.horizontal, value: .medium)
        .padding(.top, value: .regular)
    }
}

struct AIDiscoveryAlertView: View {
    let tryButton: () -> Void
    let laterButton: () -> Void

    var body: some View {
        VStack(spacing: UIPadding.medium) {
            MailResourcesAsset.aiIllustration.swiftUIImage

            Text(MailResourcesStrings.Localizable.aiDiscoveryTitle)
                .textStyle(.bodyMedium)

            Text(MailResourcesStrings.Localizable.aiDiscoveryDescription)
                .multilineTextAlignment(.center)
                .textStyle(.bodySecondary)

            ModalButtonsView(
                primaryButtonTitle: MailResourcesStrings.Localizable.buttonTry,
                secondaryButtonTitle: MailResourcesStrings.Localizable.buttonLater,
                primaryButtonAction: tryButton,
                secondaryButtonAction: laterButton
            )
        }
    }
}

#Preview {
    Group {
        AIDiscoveryBottomSheetView(tryButton: { /* Preview */ }, laterButton: { /* Preview */ })
        AIDiscoveryAlertView(tryButton: { /* Preview */ }, laterButton: { /* Preview */ })
    }
}
