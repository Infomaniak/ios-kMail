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
import SwiftUI

struct ReminderVisibilityCell: View {
    let visibility: ReminderVisibility
    let isSelected: Bool
    let isInModal: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: IKPadding.micro) {
                    if !isInModal {
                        Text(MailResourcesStrings.Localizable.reminderVisibilityTitle)
                            .textStyle(.body)
                    }
                    Text(visibility.label)
                        .textStyle(isInModal ? .body : .bodySmallSecondary)

                    if isInModal, let description = visibility.description {
                        Text(description)
                            .textStyle(.bodySmallSecondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if isSelected {
                    MailResourcesAsset.check.iconSize(.medium)
                        .foregroundStyle(Color.accentColor)
                }

                if !isInModal {
                    ChevronIcon(direction: .right, shapeStyle: MailResourcesAsset.textSecondaryColor.swiftUIColor)
                }
            }
            .padding(.leading, !isInModal ? IKIconSize.large.rawValue + IKPadding.mini : 0)
            .padding(.trailing, !isInModal ? IKPadding.medium : 0)
        }
        .padding(.vertical, !isInModal ? IKPadding.medium : 0)
        .padding(.leading, !isInModal ? IKPadding.medium : 0)
    }
}

#Preview {
    ReminderVisibilityCell(visibility: .onlyMe, isSelected: false, isInModal: false) {}
}

#Preview {
    ReminderVisibilityCell(visibility: .onlyMe, isSelected: false, isInModal: true) {}
}

#Preview {
    ReminderVisibilityCell(visibility: .onlyMe, isSelected: true, isInModal: false) {}
}

#Preview {
    ReminderVisibilityCell(visibility: .onlyMe, isSelected: true, isInModal: true) {}
}

#Preview {
    ReminderVisibilityCell(visibility: .recipientsAndMe, isSelected: false, isInModal: false) {}
}

#Preview {
    ReminderVisibilityCell(visibility: .recipientsAndMe, isSelected: false, isInModal: true) {}
}

#Preview {
    ReminderVisibilityCell(visibility: .recipientsAndMe, isSelected: true, isInModal: false) {}
}

#Preview {
    ReminderVisibilityCell(visibility: .recipientsAndMe, isSelected: true, isInModal: true) {}
}
