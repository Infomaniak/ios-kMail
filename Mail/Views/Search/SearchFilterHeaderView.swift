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

import DesignSystem
import InfomaniakCore
import InfomaniakCoreSwiftUI
import InfomaniakDI
import MailResources
import SwiftUI

struct SearchFilterHeaderView: View {
    @InjectService private var platformDetector: PlatformDetectable

    @ObservedObject var viewModel: SearchViewModel

    private var shouldShowHorizontalScrollbar: Bool {
        platformDetector.isMac
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: shouldShowHorizontalScrollbar) {
            HStack(spacing: IKPadding.mini) {
                ForEach(viewModel.filters) { filter in
                    if filter == .folder {
                        SearchFilterFolderCell(
                            mailboxManager: viewModel.mailboxManager,
                            selection: $viewModel.selectedSearchFolderId,
                            folders: viewModel.frozenFolderList
                        )
                        .accessibilityHint(MailResourcesStrings.Localizable.contentDescriptionButtonFilterSearch)
                    } else {
                        SearchFilterCell(
                            title: filter.title,
                            isSelected: viewModel.selectedFilters.contains(filter)
                        )
                        .accessibilityHint(MailResourcesStrings.Localizable.contentDescriptionButtonFilterSearch)
                        .accessibilityAddTraits(viewModel.selectedFilters.contains(filter) ? [.isSelected] : [])
                        .onTapGesture {
                            viewModel.searchFilter(filter)
                        }
                    }
                }
            }
            .padding(value: .medium)
            .padding(.bottom, shouldShowHorizontalScrollbar ? IKPadding.micro : 0)
        }
    }
}
