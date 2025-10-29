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

import DesignSystem
import InfomaniakCore
import InfomaniakCoreCommonUI
import InfomaniakCoreSwiftUI
import InfomaniakDI
import MailCore
import MailResources
import SwiftRegex
import SwiftUI

struct AddLinkView: View {
    @State private var text = ""
    @State private var url = ""

    @FocusState private var firstFieldIsFocused: Bool

    var actionHandler: ((URL, String) -> Void)?

    private var textPlaceholder: String {
        if url.isEmpty {
            return MailResourcesStrings.Localizable.addLinkTextPlaceholder
        } else {
            return url
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(MailResourcesStrings.Localizable.urlEntryTitle)
                .textStyle(.bodyMedium)
                .padding(.bottom, IKPadding.alertTitleBottom)

            VStack(spacing: IKPadding.medium) {
                TextField(textPlaceholder, text: $text)
                    .focused($firstFieldIsFocused)

                TextField(MailResourcesStrings.Localizable.urlPlaceholder, text: $url)
                    .keyboardType(.URL)
                    .disableAutocorrection(true)
                    .autocapitalization(.none)
                    .textContentType(.URL)
            }
            .textFieldStyle(.roundedBorder)
            .textStyle(.body)
            .padding(.bottom, IKPadding.alertDescriptionBottom)

            ModalButtonsView(
                primaryButtonTitle: MailResourcesStrings.Localizable.buttonValid,
                primaryButtonEnabled: !url.isEmpty,
                primaryButtonAction: didTapPrimaryButton
            )
        }
        .onAppear {
            firstFieldIsFocused = true
        }
    }

    private func didTapPrimaryButton() {
        @InjectService var matomo: MatomoUtils
        matomo.track(eventWithCategory: .editorActions, name: "addLinkConfirm")

        var correctlyFormattedURL = url
        if Regex(pattern: "^\\w+:")?.matches(in: url).isEmpty != false {
            correctlyFormattedURL = "https://\(correctlyFormattedURL)"
        }

        guard let url = URL(string: correctlyFormattedURL) else {
            @InjectService var snackbarPresenter: IKSnackBarPresentable
            snackbarPresenter.show(message: MailResourcesStrings.Localizable.snackbarInvalidUrl)
            return
        }

        actionHandler?(url, text)
    }
}

#Preview {
    AddLinkView()
}
