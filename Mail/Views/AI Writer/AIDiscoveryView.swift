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

struct AIDiscoveryView: View {
    @Environment(\.isCompactWindow) private var isCompactWindow

    @ObservedObject var aiModel: AIModel

    var body: some View {
        if isCompactWindow {
            AIDiscoveryBottomSheetView(aiModel: aiModel)
        } else {
            AIDiscoveryAlertView(aiModel: aiModel)
        }
    }
}

struct AIDiscoveryBottomSheetView: View {
    @Environment(\.dismiss) private var dismiss

    @ObservedObject var aiModel: AIModel

    var body: some View {
        VStack(spacing: 32) {
            MailResourcesAsset.aiIllustration.swiftUIImage

            Text(MailResourcesStrings.Localizable.aiDiscoveryTitle)
                .textStyle(.header2)

            Text(MailResourcesStrings.Localizable.aiDiscoveryDescription)
                .multilineTextAlignment(.center)
                .textStyle(.bodySecondary)

            VStack(spacing: UIPadding.medium) {
                MailButton(label: MailResourcesStrings.Localizable.buttonTry) {
                    dismiss()
                    aiModel.displayView(.prompt)
                }
                .mailButtonFullWidth(true)

                MailButton(label: MailResourcesStrings.Localizable.buttonLater) {
                    dismiss()
                }
                .mailButtonStyle(.link)
            }
        }
        .padding(.horizontal, value: .medium)
        .padding(.vertical, value: .regular)
    }
}

struct AIDiscoveryAlertView: View {
    @Environment(\.dismiss) private var dismiss

    @ObservedObject var aiModel: AIModel

    var body: some View {
        VStack(spacing: 0) {
            MailResourcesAsset.aiIllustration.swiftUIImage
                .padding(.bottom, UIPadding.alertTitleBottom)

            Text(MailResourcesStrings.Localizable.aiDiscoveryTitle)
                .textStyle(.bodyMedium)
                .padding(.bottom, UIPadding.alertTitleBottom)

            Text(MailResourcesStrings.Localizable.aiDiscoveryDescription)
                .multilineTextAlignment(.center)
                .textStyle(.bodySecondary)
                .padding(.bottom, UIPadding.alertDescriptionBottom)

            ModalButtonsView(
                primaryButtonTitle: MailResourcesStrings.Localizable.buttonTry,
                secondaryButtonTitle: MailResourcesStrings.Localizable.buttonLater
            ) {
                dismiss()
                aiModel.displayView(.prompt)
            }
        }
    }
}

#Preview {
    Group {
        AIDiscoveryBottomSheetView(aiModel: AIModel(mailboxManager: PreviewHelper.sampleMailboxManager))
        AIDiscoveryAlertView(aiModel: AIModel(mailboxManager: PreviewHelper.sampleMailboxManager))
    }
}
