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

struct SettingsBlockedRecipientOptionView: View {
    @ObservedObject var viewModel: SettingsBlockedRecipientViewModel

    init(mailboxManager: MailboxManager) {
        viewModel = SettingsBlockedRecipientViewModel(mailboxManager: mailboxManager)
    }

    @State private var showBlocked = true
    @State private var showAllowed = true

    var body: some View {
        VStack {
            Text(MailResourcesStrings.Localizable.settingsSecurityBlockedRecipientsDescription)
                .textStyle(.calloutSecondary)

            List {
                Section {
                    if showBlocked {
                        if let mailboxHosting = viewModel.mailboxHosting {
                            ForEach(mailboxHosting.blockedSenders, id: \.self) { recipient in
                                HStack {
                                    Text(recipient.email)
                                    Button {
                                        Task {
                                            await viewModel.removeRecipient(recipient: recipient)
                                        }

                                    } label: {
                                        Image(uiImage: MailResourcesAsset.cross.image)
                                    }
                                }
                            }
                        }
                    }
                } header: {
                    HStack {
                        Image(uiImage: MailResourcesAsset.blocked.image)
                        Text(MailResourcesStrings.Localizable.settingsSecurityBlockedOption)
                        Spacer()
                        ChevronIcon(style: showBlocked ? .down : .up)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        showBlocked.toggle()
                    }
                } footer: {
                    if showBlocked {
                        Text("Bloquer un expéditeur")
                    }
                }

                Section {
                    if showAllowed {
                        if let mailboxHosting = viewModel.mailboxHosting {
                            ForEach(mailboxHosting.authorizedSenders, id: \.self) { recipient in
                                HStack {
                                    Text(recipient.email)
                                    Button {
                                        Task {
                                            await viewModel.removeRecipient(recipient: recipient)
                                        }
                                    } label: {
                                        Image(uiImage: MailResourcesAsset.cross.image)
                                    }
                                }
                            }
                        }
                    }
                } header: {
                    HStack {
                        Image(uiImage: MailResourcesAsset.allowed.image)
                        Text(MailResourcesStrings.Localizable.settingsSecurityApprovedOption)
                        Spacer()
                        ChevronIcon(style: showAllowed ? .down : .up)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        showAllowed.toggle()
                    }
                } footer: {
                    if showAllowed {
                        Text("Autorisé un expéditeur")
                    }
                }
            }
        }

        .navigationBarTitle(MailResourcesStrings.Localizable.settingsSecurityBlockedRecipients, displayMode: .inline)
    }
}

// struct SettingsBlockedRecipientOptionView_Previews: PreviewProvider {
//    static var previews: some View {
//        SettingsBlockedRecipientOptionView()
//    }
// }
