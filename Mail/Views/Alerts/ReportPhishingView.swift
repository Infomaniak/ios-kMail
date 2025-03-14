/*
 Infomaniak Mail - iOS App
 Copyright (C) 2022 Infomaniak Network SA

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
import InfomaniakCoreSwiftUI
import InfomaniakDI
import MailCore
import MailCoreUI
import MailResources
import SwiftUI

struct ReportPhishingView: View {
    @LazyInjectService private var snackbarPresenter: SnackBarPresentable
    @EnvironmentObject private var mailboxManager: MailboxManager
    let message: Message

    var body: some View {
        VStack(spacing: 0) {
            Text(MailResourcesStrings.Localizable.reportPhishingTitle)
                .textStyle(.bodyMedium)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, IKPadding.alertTitleBottom)
            Text(MailResourcesStrings.Localizable.reportPhishingDescription)
                .textStyle(.bodySecondary)
                .padding(.bottom, IKPadding.alertDescriptionBottom)
            ModalButtonsView(primaryButtonTitle: MailResourcesStrings.Localizable.buttonConfirm, primaryButtonAction: report)
        }
    }

    private func report() async {
        await tryOrDisplayError {
            let response = try await mailboxManager.apiFetcher.reportPhishing(message: message)
            if response {
                var messages = [message.freezeIfNeeded()]
                messages.append(contentsOf: message.duplicates)
                _ = try await mailboxManager.move(messages: messages, to: .spam)
                snackbarPresenter.show(message: MailResourcesStrings.Localizable.snackbarReportPhishingConfirmation)
            }
        }
    }
}

#Preview {
    ReportPhishingView(message: PreviewHelper.sampleMessage)
        .environmentObject(PreviewHelper.sampleMailboxManager)
}
