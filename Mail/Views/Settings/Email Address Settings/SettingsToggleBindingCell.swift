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
import MailCore
import MailResources
import RealmSwift
import SwiftUI

struct SettingsToggleBindingCell: View {
    let title: String
    @State var subtitle: String
    let keyPath: ReferenceWritableKeyPath<MailboxSettings, Bool>
    @ObservedObject var viewModel: EmailAddressSettingsViewModel

    init(
        title: String,
        subtitle: String = "",
        keyPath: ReferenceWritableKeyPath<MailboxSettings, Bool>,
        viewModel: EmailAddressSettingsViewModel
    ) {
        self.title = title
        self.subtitle = viewModel.settings[keyPath: keyPath] == true
            ? MailResourcesStrings.Localizable.settingsEnabled
            : MailResourcesStrings.Localizable.settingsDisabled
        self.keyPath = keyPath
        self.viewModel = viewModel
    }

    var body: some View {
        Toggle(isOn: Binding(get: {
            viewModel.settings[keyPath: keyPath]
        }, set: { value in
            viewModel.mailboxManager.updateSettings {
                viewModel.settings[keyPath: keyPath] = value
                subtitle = value == true
                    ? MailResourcesStrings.Localizable.settingsEnabled
                    : MailResourcesStrings.Localizable.settingsDisabled
            }
            Task {
                do {
                    _ = try await viewModel.mailboxManager.apiFetcher.updateFilters(
                        ads: viewModel.settings.adsFilter,
                        spam: viewModel.settings.spamFilter,
                        mailbox: viewModel.mailboxManager.mailbox
                    )
                } catch {
                    viewModel.mailboxManager.updateSettings {
                        viewModel.settings[keyPath: keyPath] = !value
                        subtitle = viewModel.settings[keyPath: keyPath] == true
                            ? MailResourcesStrings.Localizable.settingsEnabled
                            : MailResourcesStrings.Localizable.settingsDisabled
                    }
                    IKSnackBar.showSnackBar(message: error.localizedDescription)
                }
            }
        })) {
            VStack(alignment: .leading) {
                Text(title)
                    .textStyle(.body)
                Text(subtitle)
                    .textStyle(.calloutSecondary)
            }
        }
        .tint(.accentColor)
    }
}

// struct SettingsToggleBindingCell_Previews: PreviewProvider {
//    static var previews: some View {
//        SettingsToggleBindingCell(title: "Notifications", keyPath: \.notifications, viewModel: EmailAddressSettingsViewModel(mailboxManager: <#T##MailboxManager#>))
//    }
// }
