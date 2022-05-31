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

import SwiftUI

struct SettingsToggleCellView: View {
    @EnvironmentObject var viewModel: SettingsViewModel

    var row: ParameterRow
    @State private var isOn: Bool

    init(row: ParameterRow) {
        self.row = row
        _isOn = State(initialValue: row.isOn)
    }

    var body: some View {
        Toggle(isOn: $isOn) {
            VStack(alignment: .leading, spacing: 0) {
                Text(row.title)
                    .textStyle(.body)
                if let description = row.description {
                    Text(description)
                        .textStyle(.calloutHint)
                }
            }
        }
        .onChange(of: isOn) { newValue in
            viewModel.updateToggleSettings(for: row, with: newValue)
        }
    }
}

struct SettingsToggleCellView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsToggleCellView(row: .codeLock)
    }
}
