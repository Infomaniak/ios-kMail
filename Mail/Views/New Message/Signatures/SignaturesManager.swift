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
import SwiftUI
import Sentry

final class SignaturesManager: ObservableObject {
    /// Represents the loading state
    enum SignaturesLoadingState: Equatable {
        static func == (lhs: SignaturesManager.SignaturesLoadingState, rhs: SignaturesManager.SignaturesLoadingState) -> Bool {
            switch (lhs, rhs) {
            case (.success, .success):
                return true
            case (.progress, .progress):
                return true
            case (.error(let left), .error(let right)):
                return left == right
            default:
                return false
            }
        }

        case success
        case progress
        case error(_ wrapping: NSError)
    }

    @Published var loadingSignatureState: SignaturesLoadingState = .progress

    private let mailboxManager: MailboxManager
    init(mailboxManager: MailboxManager) {
        self.mailboxManager = mailboxManager

        loadRemoteSignatures()
    }

    /// Load the signatures every time at init, set `doneLoadingDefaultSignature` to true when done
    private func loadRemoteSignatures() {
        Task {
            do {
                // load all signatures every time
                try await mailboxManager.refreshAllSignatures()
                assert(mailboxManager.getStoredSignatures().defaultSignature != nil, "Expecting a default signature")

                await MainActor.run {
                    loadingSignatureState = .success
                }
            } catch {
                await MainActor.run {
                    loadingSignatureState = .error(error as NSError)
                }

                SentrySDK.capture(message: "We failed to fetch Signatures. This will close the Editor.") { scope in
                    scope.setExtras([
                        "errorMessage": error.localizedDescription,
                        "error": "\(error)"
                    ])
                }
            }
        }
    }
}
