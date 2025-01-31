/*
 Infomaniak Mail - iOS App
 Copyright (C) 2022 Infomaniak Network SA

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

import MailResources
import SwiftUI

public struct LargePicker<SelectionValue, ButtonType>: View where SelectionValue: Hashable, ButtonType: View {
    let title: String?
    let noSelectionText: String
    let items: [Item<SelectionValue>]
    let button: Button<ButtonType>?

    @Binding var selection: SelectionValue

    public struct Item<ID>: Identifiable where ID: Hashable {
        public let id: ID
        public let name: String

        public init(id: ID, name: String) {
            self.id = id
            self.name = name
        }
    }

    private var selectedItem: Item<SelectionValue>? {
        return items.first { $0.id == selection }
    }

    public init(title: String? = nil,
                noSelectionText: String = MailResourcesStrings.Localizable.pickerNoSelection,
                selection: Binding<SelectionValue>,
                items: [Item<SelectionValue>],
                button: Button<ButtonType>?) {
        self.title = title
        self.noSelectionText = noSelectionText
        self.items = items
        self.button = button
        _selection = selection
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let title {
                Text(title)
                    .textStyle(.bodySmall)
            }

            Menu {
                button
                Picker(title ?? "", selection: $selection) {
                    ForEach(items) { item in
                        Text(item.name).tag(item.id)
                    }
                }
            } label: {
                HStack {
                    Text(selectedItem?.name ?? noSelectionText)
                        .textStyle(.body)
                    Spacer()
                    ChevronIcon(direction: .down)
                }
                .padding(value: .small)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color(hex: "#E0E0E0"))
                )
            }
        }
    }
}

public extension LargePicker where ButtonType == EmptyView {
    init(title: String? = nil,
         noSelectionText: String = MailResourcesStrings.Localizable.pickerNoSelection,
         selection: Binding<SelectionValue>,
         items: [Item<SelectionValue>]) {
        self.title = title
        self.noSelectionText = noSelectionText
        self.items = items
        button = nil
        _selection = selection
    }
}

#Preview {
    LargePicker(title: nil, selection: .constant(0), items: [.init(id: 0, name: "Value")])
}

#Preview {
    LargePicker(title: "Title", selection: .constant(0), items: [.init(id: 0, name: "Value")])
}
