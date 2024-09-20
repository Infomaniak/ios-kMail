//
/*
 Infomaniak Mail - iOS App
 Copyright (C) 2024 Infomaniak Network SA

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import MailCoreUI
import MailResources
import SwiftUI

struct ComposeMessageToolbarView: View {
    let extras: [EditorToolbarAction] = [
        .addFile,
        .addPhoto,
        .link,
    ]

    let textFormats: [EditorToolbarAction] = [
        .bold,
        .underline,
        .italic,
        .strikeThrough
        // TODO: Add remove formatter
    ]

    let textItems: [EditorToolbarAction] = [
        .unorderedList
    ]

    var body: some View {
        HStack(alignment: .center) {
            ForEach(extras, id: \.self) { extra in
                ToolbarButton(text: "", icon: extra.swiftUIicon) {
                    print("Tapped \(extra)")
                }
                .foregroundStyle(.primary)
            }
            Divider()
            ForEach(textFormats, id: \.self) { textFormat in
                ToolbarButton(text: "", icon: textFormat.swiftUIicon) {
                    print("Tapped \(textFormat)")
                }
                .foregroundStyle(.primary)
            }
            Divider()
            ForEach(textItems, id: \.self) { item in
                ToolbarButton(text: "", icon: item.swiftUIicon) {
                    print("Tapped \(item)")
                }
                .foregroundStyle(.primary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(value: .medium)
    }
}

#Preview {
    VStack {
        Text("Objet")
        ComposeMessageToolbarView()
            .ignoresSafeArea()
        Text("Message")
    }
}
