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

import MailResources
import SwiftUI

// TODO: Rename without V2

struct ComposeMessageViewV2: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {}
                .navigationTitle(MailResourcesStrings.Localizable.buttonNewMessage)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: dismissDraft) {
                            Label(MailResourcesStrings.Localizable.buttonClose, systemImage: "xmark")
                        }
                    }

                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: sendDraft) {
                            Label(MailResourcesStrings.Localizable.buttonClose, image: "xmark")
                            Label(MailResourcesStrings.Localizable.send, image: MailResourcesAsset.send.name)
                        }
                    }
                }
        }
    }

    private func dismissDraft() {
        // TODO: Check attachments
        dismiss()
    }

    private func sendDraft() {
        // TODO: Check attachments
        dismiss()
    }
}

struct ComposeMessageViewV2_Previews: PreviewProvider {
    static var previews: some View {
        ComposeMessageViewV2()
    }
}
