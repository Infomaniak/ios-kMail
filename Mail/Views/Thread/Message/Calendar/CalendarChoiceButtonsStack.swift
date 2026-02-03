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

import DesignSystem
import InfomaniakCoreSwiftUI
import MailCore
import MailCoreUI
import SwiftUI

struct CalendarChoiceButtonsStack: View {
    @State private var selectedChoice: AttendeeState?

    let currentState: AttendeeState?
    let messageUid: String?

    init(currentState: AttendeeState?, messageUid: String?) {
        self.currentState = currentState
        self.messageUid = messageUid

        _selectedChoice = State(wrappedValue: currentState)
    }

    var body: some View {
        FlowLayout(alignment: .leading, verticalSpacing: IKPadding.mini, horizontalSpacing: IKPadding.mini) {
            ForEach(AttendeeState.allCases) { choice in
                CalendarChoiceButton(
                    selectedChoice: $selectedChoice,
                    choice: choice,
                    isSelected: selectedChoice == choice,
                    messageUid: messageUid
                )
            }
        }
        .onChange(of: currentState) { newState in
            if newState != selectedChoice {
                selectedChoice = newState
            }
        }
    }
}

#Preview {
    CalendarChoiceButtonsStack(currentState: .yes, messageUid: "")
}
