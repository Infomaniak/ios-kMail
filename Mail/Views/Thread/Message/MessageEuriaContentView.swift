/*
 Infomaniak Mail - iOS App
 Copyright (C) 2025 Infomaniak Network SA

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
import MailCore
import MailCoreUI
import MailResources
import RealmSwift
import SwiftUI

struct MessageEuriaContentView: View {
    let isLoading: Bool
    let content: String?
    let dismissAction: () -> Void

    private var title: String {
        if isLoading {
            return MailResourcesStrings.Localizable.messageSummaryLoading
        }
        return MailResourcesStrings.Localizable.messageSummary
    }

    var body: some View {
        VStack(alignment: .leading, spacing: IKPadding.small) {
            HStack(spacing: 6) {
                EuriaAnimationView(size: .medium)
                Text(title)
                    .textStyle(.bodySmallMedium)

                Spacer()

                CloseButton(size: .medium) { dismissAction() }
            }

            if let content {
                Text(content)
                    .textStyle(.bodySmall)
            }
        }
        .padding(value: .small)
        .background {
            RoundedRectangle(cornerRadius: IKRadius.medium)
                .foregroundStyle(MailResourcesAsset.backgroundBlueNavBarColor.swiftUIColor)
        }
        .padding(value: .medium)
        .animation(.default, value: content)
    }
}

#Preview {
    MessageEuriaContentView(isLoading: false, content: "") {}
}
