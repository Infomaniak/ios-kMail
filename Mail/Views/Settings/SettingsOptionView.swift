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

import InfomaniakCore
import InfomaniakDI
import MailCore
import MailResources
import SwiftUI

struct SettingsOptionView<OptionEnum>: View where OptionEnum: CaseIterable, OptionEnum: Equatable, OptionEnum: RawRepresentable,
    OptionEnum: SettingsOptionEnum, OptionEnum.AllCases: RandomAccessCollection, OptionEnum.RawValue: Hashable {
    private let title: String
    private let subtitle: String?
    private let allValues: [OptionEnum]
    private let keyPath: ReferenceWritableKeyPath<UserDefaults, OptionEnum>
    private let excludedKeyPaths: [ReferenceWritableKeyPath<UserDefaults, OptionEnum>]?

    private let matomoCategory: MatomoUtils.EventCategory?
    private let matomoValue: Float?
    private let matomoName: KeyPath<OptionEnum, String>?

    @State private var values: [OptionEnum]
    @State private var selectedValue: OptionEnum {
        didSet {
            UserDefaults.shared[keyPath: keyPath] = selectedValue
            switch keyPath {
            case \.theme, \.accentColor:
                UIApplication.shared.connectedScenes.forEach { ($0.delegate as? SceneDelegate)?.updateWindowUI() }
            default:
                break
            }
        }
    }

    @LazyInjectService private var matomo: MatomoUtils

    init(title: String,
         subtitle: String? = nil,
         values: [OptionEnum] = Array(OptionEnum.allCases),
         keyPath: ReferenceWritableKeyPath<UserDefaults, OptionEnum>,
         excludedKeyPath: [ReferenceWritableKeyPath<UserDefaults, OptionEnum>]? = nil,
         matomoCategory: MatomoUtils.EventCategory? = nil,
         matomoName: KeyPath<OptionEnum, String>? = nil,
         matomoValue: Float? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.keyPath = keyPath
        excludedKeyPaths = excludedKeyPath
        allValues = values

        self.matomoCategory = matomoCategory
        self.matomoName = matomoName
        self.matomoValue = matomoValue

        _values = State(wrappedValue: values)
        _selectedValue = State(wrappedValue: UserDefaults.shared[keyPath: keyPath])
    }

    var body: some View {
        List {
            Section {
                ForEach(values, id: \.rawValue) { value in
                    Button {
                        if let matomoCategory, let matomoName {
                            matomo.track(eventWithCategory: matomoCategory, name: value[keyPath: matomoName], value: matomoValue)
                        }
                        selectedValue = value
                    } label: {
                        VStack(spacing: 0) {
                            HStack(spacing: 16) {
                                value.image?
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 24, height: 24)
                                    .foregroundColor(MailResourcesAsset.textTertiaryColor)
                                Text(value.title)
                                    .textStyle(.body)
                                Spacer()
                                if value == selectedValue {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                            .padding(.vertical, 16)
                            .padding(.horizontal, 24)

                            if value != values.last {
                                IKDivider()
                                    .padding(.horizontal, 8)
                            }
                        }
                    }
                }
                .listRowSeparator(.hidden)
                .listRowInsets(.init())
            } header: {
                if let subtitle = subtitle {
                    Text(subtitle)
                        .textStyle(.bodySmallSecondary)
                } else {
                    EmptyView()
                }
            }
            .background(MailResourcesAsset.backgroundSecondaryColor.swiftUiColor)
        }
        .listStyle(.plain)
        .background(MailResourcesAsset.backgroundSecondaryColor.swiftUiColor)
        .navigationBarTitle(title, displayMode: .inline)
        .onAppear {
            guard let excludedKeyPaths else { return }
            let excludedValues = excludedKeyPaths.map { UserDefaults.shared[keyPath: $0] }
            self.values = allValues.filter { !excludedValues.contains($0) || ($0.rawValue as? String) == "none" }
        }
        .matomoView(view: [MatomoUtils.View.settingsView.displayName, String(describing: OptionEnum.self)])
    }
}

struct SettingsOptionView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsOptionView<Theme>(title: "Theme", subtitle: "Theme", keyPath: \.theme)
    }
}
