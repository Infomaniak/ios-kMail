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

struct ReplaceMessageContentView: View {
    @State private var doNotShowAIReplaceMessageAgain = UserDefaults.shared.doNotShowAIReplaceMessageAgain

    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(MailResourcesStrings.Localizable.aiReplacementDialogTitle)
                .textStyle(.bodyMedium)
                .padding(.bottom, UIPadding.alertTitleBottom)

            VStack(alignment: .leading, spacing: UIPadding.medium) {
                Text(MailResourcesStrings.Localizable.aiReplacementDialogDescription)

                Toggle(MailResourcesStrings.Localizable.aiReplacementDialogDoNotShowAgain, isOn: $doNotShowAIReplaceMessageAgain)
                    .toggleStyle(CheckmarkToggleStyle())
            }
            .textStyle(.bodySecondary)
            .padding(.bottom, UIPadding.alertDescriptionBottom)

            ModalButtonsView(primaryButtonTitle: MailResourcesStrings.Localizable.aiReplacementDialogPositiveButton) {
                UserDefaults.shared.doNotShowAIReplaceMessageAgain = doNotShowAIReplaceMessageAgain
                action()
            }
        }
    }
}

struct ReplaceMessageContentView_Preview: PreviewProvider {
    static var previews: some View {
        ReplaceMessageContentView { /* Preview */ }
    }
}
