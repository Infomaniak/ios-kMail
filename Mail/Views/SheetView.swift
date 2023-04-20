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

struct SheetView<Content>: View where Content: View {
    @Environment(\.dismiss) private var dismiss

    @ViewBuilder let content: Content

    var body: some View {
        NavigationView {
            content
                .navigationBarItems(leading: Button {
                    dismiss()
                } label: {
                    Label(MailResourcesStrings.Localizable.buttonClose, systemImage: "xmark")
                })
        }
        .onReceive(NotificationCenter.default.publisher(for: Constants.dismissMoveSheetNotificationName)) { _ in
            dismiss()
        }
    }
}

struct SheetView_Previews: PreviewProvider {
    static var previews: some View {
        SheetView {
            EmptyView()
        }
    }
}
