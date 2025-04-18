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

import MailResources
import SwiftUI

public struct SyncStepToolbarItem: View {
    let step: Int
    let totalSteps: Int

    public init(step: Int, totalSteps: Int) {
        self.step = step
        self.totalSteps = totalSteps
    }

    public var body: some View {
        VStack {
            Text(MailResourcesStrings.Localizable.syncTutorialStepCount(step, totalSteps))
                .textStyle(.bodyMedium)
                .padding(value: .mini)
                .background(RoundedRectangle(cornerRadius: 8).fill(MailResourcesAsset.textFieldBorder.swiftUIColor))
        }
        .padding(value: .medium)
    }
}

#Preview {
    SyncStepToolbarItem(step: 1, totalSteps: 3)
}
