/*
 Infomaniak Mail - iOS App
 Copyright (C) 2024 Infomaniak Network SA

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
import SwiftUI

struct ThreadCellTextView: View {
    public enum ThreadCellTextType {
        case subject
        case preview

        public var style: MailTextStyle {
            switch self {
            case .subject:
                return .body
            case .preview:
                return .bodySmallSecondary
            }
        }
    }

    let title: String
    let type: ThreadCellTextType

    var body: some View {
        Text(title)
            .textStyle(type.style)
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    ThreadCellTextView(title: "Subject", type: .subject)
}
