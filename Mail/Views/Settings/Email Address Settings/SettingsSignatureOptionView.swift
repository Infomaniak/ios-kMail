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

struct SettingsSignatureOptionView: View {
    var mailboxManager: MailboxManager
    @State var signatureResponse: SignatureResponse

//    @State var editSignature = false
//    @State var addSignature = false

    init(mailboxManager: MailboxManager) {
        self.mailboxManager = mailboxManager
        signatureResponse = mailboxManager.getSignatureResponse()!
    }

    var body: some View {
        VStack(spacing: 30) {
//            Text(MailResourcesStrings.Localizable.settingsSelectSignatureDescription)
//            .frame(maxWidth: .infinity, alignment: .leading)
//            .textStyle(.header3)

            ForEach(signatureResponse.signatures) { signature in
                HStack {
                    Text(signature.name)
                    NavigationLink {
                        SettingsSignatureView()
                    } label: {
                        Image(resource: MailResourcesAsset.edit)
                            .resizable()
                            .frame(width: 12, height: 12)
                            .onTapGesture {
                                print("edit")
                            }
                    }

                    Spacer()
                    if isSelected(id: signature.id) {
                        Image(systemName: "checkmark")
                            .foregroundColor(.accentColor)
                    }
                }
                .foregroundColor(isSelected(id: signature.id) ? .accentColor : .primary)
                .onTapGesture {
                    print("select")
                }
            }
            
//            List(signatureResponse.signatures) { signature in
//                HStack {
//                    Text(signature.name)
//                    NavigationLink(isActive: $editSignature) {
//                        SettingsSignatureView()
//                    } label: {
//                        Image(resource: MailResourcesAsset.edit)
//                            .resizable()
//                            .frame(width: 12, height: 12)
//                            .onTapGesture {
//                                print("edit")
//                            }
//                    }
//
//                    Spacer()
//                    if isSelected(id: signature.id) {
//                        Image(systemName: "checkmark")
//                            .foregroundColor(.accentColor)
//                    }
//                }
//                .foregroundColor(isSelected(id: signature.id) ? .accentColor : .primary)
//                .onTapGesture {
//                    print("select")
//                }
//            }

            NavigationLink {
                SettingsSignatureView()
            } label: {
                Text("Créer une signature")
            }
        }
    }

    private func isSelected(id: Int) -> Bool {
        return signatureResponse.defaultSignatureId == id
    }
}

// struct SettingsSignatureOptionView_Previews: PreviewProvider {
//    static var previews: some View {
//        SettingsSignatureOptionView()
//    }
// }
