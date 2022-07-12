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
import MailCore
import MailResources
import Sentry
import SwiftUI

struct ReportDisplayProblemView: View {
    let mailboxManager: MailboxManager
    @ObservedObject var state: GlobalBottomSheet
    let message: Message

    var body: some View {
        VStack(spacing: 16) {
            Text(MailResourcesStrings.Localizable.reportDisplayProblemTitle)
                .textStyle(.header3)
                .frame(maxWidth: .infinity, alignment: .leading)
            Image(resource: MailResourcesAsset.displayIssue)
            Text(MailResourcesStrings.Localizable.reportDisplayProblemDescription)
                .textStyle(.bodySecondary)
            HStack(spacing: 24) {
                Button(MailResourcesStrings.Localizable.buttonRefuse) {
                    state.close()
                }

                BottomSheetButton(label: MailResourcesStrings.Localizable.buttonAccept, action: report)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.top, 8)
        }
        .padding(.horizontal, Constants.bottomSheetHorizontalPadding)
    }

    private func report() {
        state.close()
        Task {
            await tryOrDisplayError {
                // Download message
                let fileURL = try await mailboxManager.apiFetcher.download(message: message)
                // Send it via Sentry
                let fileAttachment = Attachment(path: fileURL.path,
                                                filename: fileURL.lastPathComponent,
                                                contentType: "message/rfc822")
                _ = SentrySDK.capture(message: "Message display problem reported") { scope in
                    scope.add(fileAttachment)
                }
                IKSnackBar.showSnackBar(message: MailResourcesStrings.Localizable.snackbarDisplayProblemReported)
            }
        }
    }
}

struct ReportDisplayProblemView_Previews: PreviewProvider {
    static var previews: some View {
        ReportDisplayProblemView(mailboxManager: PreviewHelper.sampleMailboxManager,
                                 state: GlobalBottomSheet(),
                                 message: PreviewHelper.sampleMessage)
    }
}
