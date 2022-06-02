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
import MailResources

struct SettingsSelectionView: View {
    @StateObject var viewModel: SettingsSelectionViewModel

    init(viewModel: SettingsSelectionViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            if let header = viewModel.header {
                SettingsSectionHeaderView(title: header, separator: false)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    ForEach(viewModel.tableContent) { element in
                        HStack {
                            element.view
                                .textStyle(element.isSelected ? .button : .body)
                            Spacer()
                            if element.isSelected {
                                Image(systemName: "checkmark")
                                    .foregroundColor(MailResourcesAsset.infomaniakColor)
                            }
                        }
                        .onTapGesture {
                            viewModel.updateSelection(newValue: element.id)
                        }
                    }
                }
            }
            .padding([.leading, .trailing], 16)
        }
        .navigationTitle(viewModel.title)
        .padding(16)
    }
}

struct SettingsSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsSelectionView(viewModel: ThemeSettingViewModel())
    }
}
