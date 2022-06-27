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

struct SettingsOptionView<OptionEnum>: View where OptionEnum: CaseIterable, OptionEnum: Equatable, OptionEnum: RawRepresentable,
    OptionEnum: SettingsOptionEnum, OptionEnum.AllCases: RandomAccessCollection, OptionEnum.RawValue: Hashable {
    let title: String
    let subtitle: String?
    let keyPath: ReferenceWritableKeyPath<UserDefaults, OptionEnum>
    let excludedKeyPath: [ReferenceWritableKeyPath<UserDefaults, OptionEnum>]?

    @State private var values = Array(OptionEnum.allCases)

    @State private var selectedValue: OptionEnum {
        didSet {
            UserDefaults.shared[keyPath: keyPath] = selectedValue
            if keyPath == \.theme {
                (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.window?
                    .overrideUserInterfaceStyle = UserDefaults.shared.theme.interfaceStyle
            }
        }
    }

    init(title: String,
         subtitle: String? = nil,
         keyPath: ReferenceWritableKeyPath<UserDefaults, OptionEnum>,
         excludedKeyPath: [ReferenceWritableKeyPath<UserDefaults, OptionEnum>]? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.keyPath = keyPath
        self.excludedKeyPath = excludedKeyPath
        _selectedValue = State(wrappedValue: UserDefaults.shared[keyPath: keyPath])    }

    var body: some View {
        List {
            Section {
                ForEach(values, id: \.rawValue) { value in
                    Button {
                        selectedValue = value
                    } label: {
                        HStack(spacing: 21) {
                            value.image
                                .foregroundColor(MailResourcesAsset.hintTextColor)
                            Text(value.title)
                                .textStyle(value == selectedValue ? .button : .body)
                            Spacer()
                            if value == selectedValue {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                }
                .listRowSeparator(.hidden)
            } header: {
                if let subtitle = subtitle {
                    Text(subtitle)
                        .textStyle(.header3)
                } else {
                    EmptyView()
                }
            }
        }
        .listStyle(.plain)
        .navigationBarTitle(title, displayMode: .inline)
        .onAppear {
            updateOptions()
        }
    }

    private func updateOptions() {
        if let excludedKeyPath = excludedKeyPath {
            let excludedValues = excludedKeyPath.map { UserDefaults.shared[keyPath: $0] }
            values = values.filter { !excludedValues.contains($0) || ($0.rawValue as? String) == "none" }
        }
    }
}

struct SettingsOptionView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsOptionView<Theme>(title: "Theme", subtitle: "Theme", keyPath: \.theme)
    }
}
