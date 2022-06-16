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

struct SettingsSwipeActionsView: View {
    @ObservedObject var viewModel: SwipeActionSettingsViewModel

    init(viewModel: SwipeActionSettingsViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        List {
            ForEach(viewModel.sections) { section in
                Section {
                    ForEach(section.items) { item in
                        switch item.type {
                        case let .option(option):
                            SettingsOptionCell(
                                title: item.title,
                                subtitle: viewModel.selectedValues[option]?.title ?? "",
                                option: option
                            )
                        default:
                            EmptyView()
                        }
                    }
                    .listRowSeparator(.hidden)
                } footer: {
                    SwipeConfigCell(selectedValues: viewModel.selectedValues, section: section)
                }
                .listSectionSeparator(viewModel.sections.last == section ? .hidden : .visible, edges: .bottom)
            }
        }
        .listStyle(.plain)
        .navigationBarTitle(viewModel.title)
        .onAppear {
            viewModel.updateSelectedValue()
        }
    }
}

struct SettingsSwipeActionsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsSwipeActionsView(viewModel: SwipeActionSettingsViewModel())
    }
}
