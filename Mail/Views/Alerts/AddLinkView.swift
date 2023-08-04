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
import InfomaniakCoreUI
import InfomaniakDI
import MailCore
import MailResources
import SwiftUI

struct AddLinkView: View {
    @State private var url = ""
    @FocusState private var isFocused: Bool

    @LazyInjectService private var snackbarPresenter: SnackBarPresentable
    @LazyInjectService private var matomo: MatomoUtils

    var actionHandler: ((String) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text(MailResourcesStrings.Localizable.urlEntryTitle)
                .textStyle(.bodyMedium)
            TextField(MailResourcesStrings.Localizable.urlPlaceholder, text: $url)
                .textFieldStyle(.roundedBorder)
                .focused($isFocused)
                .keyboardType(.URL)
                .disableAutocorrection(true)
                .autocapitalization(.none)
                .textContentType(.URL)
                .textStyle(.body)
            ModalButtonsView(
                primaryButtonTitle: MailResourcesStrings.Localizable.buttonValid,
                primaryButtonEnabled: !url.isEmpty
            ) {
                matomo.track(eventWithCategory: .editorActions, name: "addLinkConfirm")

                guard var urlComponents = URLComponents(string: url) else {
                    snackbarPresenter.show(message: MailResourcesStrings.Localizable.snackbarInvalidUrl)
                    return
                }
                if urlComponents.scheme == nil {
                    urlComponents.scheme = URLConstants.schemeUrl
                }
                guard let url = urlComponents.url?.absoluteString else {
                    snackbarPresenter.show(message: MailResourcesStrings.Localizable.snackbarInvalidUrl)
                    return
                }
                actionHandler?(url)
            }
        }
        .onAppear {
            isFocused = true
        }
    }
}

struct AddLinkView_Previews: PreviewProvider {
    static var previews: some View {
        AddLinkView()
    }
}
