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

import Introspect
import MailCore
import MailResources
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var menuSheet: MenuSheet
    @State var viewModel: SettingsViewModel

    init(viewModel: SettingsViewModel = SettingsViewModel()) {
        self.viewModel = viewModel
    }

    var body: some View {
        ScrollView {
            VStack {
                ForEach(viewModel.tableContent) { section in
                    Section {
                        VStack(spacing: 25) {
                            ForEach(section.content) { row in
                                SettingsRowView(row: row)
                            }
                        }
                        .padding([.leading, .trailing], 16)
                        .listRowSeparator(.hidden)
                    } header: {
                        SettingsSectionHeaderView(title: section.title, separator: !(section == viewModel.tableContent.first))
                    }
                }
            }
            .environmentObject(viewModel)
        }
        .navigationBarTitle("Settings")
        .backButtonDisplayMode(.minimal)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
