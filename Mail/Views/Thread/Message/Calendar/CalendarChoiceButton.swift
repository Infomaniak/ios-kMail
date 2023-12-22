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

enum CalendarChoice {
    case yes, maybe, no

    var icon: MailResourcesImages {
        switch self {
        case .yes:
            return MailResourcesAsset.checkmarkCircleFill
        case .maybe:
            return MailResourcesAsset.questionmarkCircleFill
        case .no:
            return MailResourcesAsset.crossCircleFill
        }
    }

    var label: String {
        switch self {
        case .yes:
            return MailResourcesStrings.Localizable.buttonYes
        case .maybe:
            return MailResourcesStrings.Localizable.buttonMaybe
        case .no:
            return MailResourcesStrings.Localizable.buttonNo
        }
    }

    var color: Color {
        switch self {
        case .yes:
            return MailResourcesAsset.greenColor.swiftUIColor
        case .maybe:
            return MailResourcesAsset.textSecondaryColor.swiftUIColor
        case .no:
            return MailResourcesAsset.redColor.swiftUIColor
        }
    }
}

struct CalendarChoiceButton: View {
    let choice: CalendarChoice
    let isSelected: Bool

    var body: some View {
        Button {
            // TODO: Select item
        } label: {
            HStack(spacing: UIPadding.small) {
                IKIcon(choice.icon)
                    .foregroundStyle(choice.color)
                Text(choice.label)
                    .textStyle(.bodyMedium)
            }
            .padding(.horizontal, value: .intermediate)
            .padding(.vertical, value: .small)
            .overlay {
                RoundedRectangle(cornerRadius: 30)
                    .stroke(isSelected ? choice.color : MailResourcesAsset.textFieldBorder.swiftUIColor)
            }
        }
        .allowsHitTesting(!isSelected)
    }
}

#Preview {
    VStack {
        HStack {
            CalendarChoiceButton(choice: .yes, isSelected: false)
            CalendarChoiceButton(choice: .maybe, isSelected: false)
            CalendarChoiceButton(choice: .no, isSelected: false)
        }

        HStack {
            CalendarChoiceButton(choice: .yes, isSelected: true)
            CalendarChoiceButton(choice: .maybe, isSelected: true)
            CalendarChoiceButton(choice: .no, isSelected: true)
        }
    }
}
