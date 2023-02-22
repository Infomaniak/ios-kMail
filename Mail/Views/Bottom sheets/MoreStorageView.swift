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

struct MoreStorageView: View {
    let state: GlobalBottomSheet

    var body: some View {
        VStack(alignment: .leading) {
            Text(MailResourcesStrings.Localizable.moreStorageTitle)
                .textStyle(.bodyMedium)

            Image(resource: MailResourcesAsset.moreStorage)
                .resizable()
                .scaledToFit()
                .frame(width: 245)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 15)
                .padding(.bottom, 17)

            VStack(alignment: .leading, spacing: 15) {
                Text(MailResourcesStrings.Localizable.moreStorageText1)
                Text(MailResourcesStrings.Localizable.moreStorageText2)
            }
            .textStyle(.bodySecondary)
            .padding(.bottom, 24)

            ModalButtonsView(primaryButtonTitle: MailResourcesStrings.Localizable.buttonAvailableSoon,
                                   secondaryButtonTitle: MailResourcesStrings.Localizable.buttonClose,
                                   primaryButtonEnabled: false,
                                   primaryButtonAction: getMoreStorage,
                                   secondaryButtonAction: dismiss)
        }
        .padding(.horizontal, Constants.bottomSheetHorizontalPadding)
    }

    // MARK: - Actions

    private func dismiss() {
        state.close()
    }

    private func getMoreStorage() {
        // TODO: Implement when functionality is available
    }
}

struct MoreStorageView_Previews: PreviewProvider {
    static var previews: some View {
        MoreStorageView(state: GlobalBottomSheet())
            .previewLayout(.sizeThatFits)
    }
}
