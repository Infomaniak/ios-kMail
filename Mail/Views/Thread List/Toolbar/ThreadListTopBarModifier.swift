/*
 Infomaniak Mail - iOS App
 Copyright (C) 2025 Infomaniak Network SA

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

import InfomaniakCoreCommonUI
import InfomaniakDI
import MailCore
import MailCoreUI
import MailResources
import SwiftUI

extension View {
    @ViewBuilder func threadListTopBar(viewModel: ThreadListViewModel,
                                       multipleSelectionViewModel: MultipleSelectionViewModel) -> some View {
        if #available(iOS 26.0, *) {
            modifier(ThreadListTopBarModifier(viewModel: viewModel, multipleSelectionViewModel: multipleSelectionViewModel))
        } else {
            modifier(LegacyThreadListTopBarModifier(viewModel: viewModel, multipleSelectionViewModel: multipleSelectionViewModel))
        }
    }
}

// MARK: - iOS 26+ Toolbar

@available(iOS 26.0, *)
struct ThreadListTopBarModifier: ViewModifier {
    @Environment(\.isCompactWindow) private var isCompactWindow

    @ObservedObject var viewModel: ThreadListViewModel
    @ObservedObject var multipleSelectionViewModel: MultipleSelectionViewModel

    private var navigationTitle: String {
        if multipleSelectionViewModel.isEnabled {
            return MailResourcesStrings.Localizable.multipleSelectionCount(multipleSelectionViewModel.selectedItems.count)
        } else {
            return viewModel.frozenFolder.localizedName
        }
    }

    private var selectAllButtonTitle: String {
        if multipleSelectionViewModel.selectedItems.count == viewModel.filteredThreads.count {
            return MailResourcesStrings.Localizable.buttonUnselectAll
        } else {
            return MailResourcesStrings.Localizable.buttonSelectAll
        }
    }

    func body(content: Content) -> some View {
        content
            .scrollEdgeEffectStyle(.hard, for: .top)
            .navigationTitle(navigationTitle)
            .toolbarTitleDisplayMode(.inline)
            .toolbarBackground(UserDefaults.shared.accentColor.navBarBackground.swiftUIColor, for: .navigationBar)
            .toolbarBackgroundVisibility(.visible, for: .navigationBar)
            .toolbar {
                if !multipleSelectionViewModel.isEnabled {
                    if isCompactWindow {
                        ToolbarItem(placement: .topBarLeading) { MenuDrawerButton() }
                    }

                    ToolbarItem(placement: .topBarTrailing) { SearchButton() }
                    ToolbarSpacer(.fixed, placement: .topBarTrailing)
                    ToolbarItem(placement: .topBarTrailing) { AccountButton() }
                }
            }
            .toolbar {
                if multipleSelectionViewModel.isEnabled {
                    ToolbarItem(placement: .cancellationAction) { cancelMultipleSelectionButton }
                    ToolbarItem(placement: .primaryAction) { selectAllButton }
                }
            }
    }

    private var cancelMultipleSelectionButton: some View {
        Button(MailResourcesStrings.Localizable.buttonCancel, role: .cancel) {
            @InjectService var matomo: MatomoUtils
            matomo.track(eventWithCategory: .multiSelection, name: "cancel")
            multipleSelectionViewModel.disable()
        }
    }

    private var selectAllButton: some View {
        Button(selectAllButtonTitle) {
            withAnimation(.default.speed(2)) {
                multipleSelectionViewModel.selectAll(threads: viewModel.filteredThreads)
            }
        }
        .animation(nil, value: multipleSelectionViewModel.selectedItems)
    }
}

// MARK: - iOS 18- Toolbar

@available(iOS, deprecated: 26.0, message: "Use ThreadListTopBarModifier with Liquid Glass design")
struct LegacyThreadListTopBarModifier: ViewModifier {
    @Environment(\.isCompactWindow) private var isCompactWindow

    @ObservedObject var viewModel: ThreadListViewModel
    @ObservedObject var multipleSelectionViewModel: MultipleSelectionViewModel

    private var selectAllButtonTitle: String {
        if multipleSelectionViewModel.selectedItems.count == viewModel.filteredThreads.count {
            return MailResourcesStrings.Localizable.buttonUnselectAll
        } else {
            return MailResourcesStrings.Localizable.buttonSelectAll
        }
    }

    func body(content: Content) -> some View {
        GeometryReader { geometry in
            content
                .navigationBarThreadListStyle()
                .toolbar {
                    ToolbarItemGroup(placement: .navigationBarLeading) {
                        if multipleSelectionViewModel.isEnabled {
                            Button(MailResourcesStrings.Localizable.buttonCancel, role: .cancel) {
                                @InjectService var matomo: MatomoUtils
                                matomo.track(eventWithCategory: .multiSelection, name: "cancel")
                                multipleSelectionViewModel.disable()
                            }
                        } else {
                            if isCompactWindow {
                                MenuDrawerButton()
                            }

                            Text(viewModel.frozenFolder.localizedName)
                                .textStyle(.header1)
                                .frame(maxWidth: maxTextWidth(geometry), alignment: .leading)
                        }
                    }

                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        if multipleSelectionViewModel.isEnabled {
                            Button(selectAllButtonTitle) {
                                withAnimation(.default.speed(2)) {
                                    multipleSelectionViewModel.selectAll(threads: viewModel.filteredThreads)
                                }
                            }
                            .animation(nil, value: multipleSelectionViewModel.selectedItems)
                        } else {
                            SearchButton()

                            AccountButton()
                        }
                    }
                }
                .navigationTitle(
                    multipleSelectionViewModel.isEnabled
                        ? MailResourcesStrings.Localizable.multipleSelectionCount(multipleSelectionViewModel.selectedItems.count)
                        : ""
                )
                .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func maxTextWidth(_ proxy: GeometryProxy) -> CGFloat {
        guard isCompactWindow else {
            return 215
        }

        let safeAreaHorizontalInsets = proxy.safeAreaInsets.leading + proxy.safeAreaInsets.trailing

        let toolbarIconSize: CGFloat = 24
        let toolbarIconPadding: CGFloat = 16
        let toolbarIconsSpace = toolbarIconSize * 3 + (toolbarIconPadding * 5)

        return max(0, proxy.size.width - safeAreaHorizontalInsets - toolbarIconsSpace)
    }
}
