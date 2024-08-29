/*
 Infomaniak Mail - iOS App
 Copyright (C) 2024 Infomaniak Network SA

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

import MailCore
import SwiftUI

struct AccountActionsView: View {
    private var actions: [Action] {
        return [.addAccount, .logoutAccount]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(actions) { action in
                Button {
                    handleAction(action)
                } label: {
                    ActionButtonLabel(action: action)
                }
            }
        }
    }

    // MARK: - Actions

    private func handleAction(_ action: Action) {
        switch action {
        case .addAccount:
            addAccount()
        case .logoutAccount:
            logoutAccount()
        default:
            return
        }
    }

    private func addAccount() {
        // TODO: handle action
    }

    private func logoutAccount() {
        // TODO: handle action
    }
}

#Preview {
    AccountActionsView()
}
