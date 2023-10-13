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

struct AIDismissibleErrorView: View {
    @State private var isShowingError = false

    let error: MailError?

    private var message: String {
        guard let error else { return "" }
        if error == .unknownError {
            return MailResourcesStrings.Localizable.aiErrorUnknown
        } else {
            return error.localizedDescription
        }
    }

    var body: some View {
        Group {
            if isShowingError {
                InformationBlockView(icon: MailResourcesAsset.warning.swiftUIImage, message: message) {
                    withAnimation {
                        isShowingError = false
                    }
                }
            }
        }
        .onChange(of: error) { newError in
            withAnimation {
                isShowingError = newError != nil
            }
        }
    }
}

#Preview {
    AIDismissibleErrorView(error: .unknownError)
}
