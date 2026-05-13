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

struct MessageEuriaContentView<Content: View>: View {
    private let title: String
    private let isError: Bool
    private let content: Content?
    private let dismissAction: () -> Void

    init(title: String, isError: Bool, @ViewBuilder content: () -> Content?, dismiss: @escaping () -> Void) {
        self.title = title
        self.isError = isError
        self.content = content()
        dismissAction = dismiss
    }

    var body: some View {
        VStack(alignment: .leading, spacing: IKPadding.small) {
            HStack(spacing: IKPadding.mini) {
                if isError {
                    MailResourcesAsset.warningFill.swiftUIImage
                        .iconSize(.medium)
                        .foregroundStyle(MailResourcesAsset.orangeColor.swiftUIColor)
                        .accessibilityLabel(MailResourcesStrings.Localizable.contentDescriptionButtonWarning)
                } else {
                    EuriaAnimationView(size: .medium)
                }

                Text(title)
                    .textStyle(.bodySmallMedium)

                Spacer()

                CloseButton(size: .medium) { dismissAction() }
            }

            if let content {
                content
            }
        }
        .padding(value: .small)
        .background {
            RoundedRectangle(cornerRadius: IKRadius.medium)
                .foregroundStyle(MailResourcesAsset.backgroundBlueNavBarColor.swiftUIColor)
        }
    }
}

#Preview {
    MessageEuriaContentView(title: "Title", isError: false) {} dismiss: {}
}
