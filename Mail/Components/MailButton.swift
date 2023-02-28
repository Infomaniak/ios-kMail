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

struct MailButton: View {
    let icon: MailResourcesImages?
    let label: String?
    let action: () -> Void

    var style = Style.link

    enum Style {
        case large, link, smallLink, destructive
    }

    init(icon: MailResourcesImages? = nil, label: String, action: @escaping () -> Void) {
        self.icon = icon
        self.label = label
        self.action = action
    }

    init(icon: MailResourcesImages, action: @escaping () -> Void) {
        self.icon = icon
        self.label = nil
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon {
                    Image(resource: icon)
                        .resizable()
                        .frame(width: 16, height: 16)
                }
                if let label {
                    Text(label)
                }
            }
        }
    }
}

struct MailButton_Previews: PreviewProvider {
    @available(iOS 16.0, *)
    private static var buttonsRow: some View {
        GridRow {
            MailButton(label: "Link") { /* Preview */ }
            MailButton(label: "Large") { /* Preview */ }
            MailButton(label: "Small Link") { /* Preview */ }

            MailButton(icon: MailResourcesAsset.synchronizeArrow, label: "Link") { /* Preview */ }
            MailButton(icon: MailResourcesAsset.pencil, label: "Large") { /* Preview */ }
            MailButton(icon: MailResourcesAsset.pencil) { /* Preview */ }
        }
    }

    static var previews: some View {
        Group {
            if #available(iOS 16.0, *) {
                Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 20) {
                    buttonsRow

                    buttonsRow
                        .disabled(true)

                    GridRow {
                        MailButton(label: "Red Link") { /* Preview */ }
                    }
                }
                MailButton(icon: MailResourcesAsset.pencil, label: "Full Width") { /* Preview */ }
            } else {
                MailButton(label: "Link") { /* Preview */ }
            }
        }
        .previewInterfaceOrientation(.landscapeLeft)
    }
}
