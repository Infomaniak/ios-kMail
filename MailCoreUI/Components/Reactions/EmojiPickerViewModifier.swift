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

import ElegantEmojiPicker
import InfomaniakCore
import InfomaniakDI
import MailResources
import SwiftUI

extension View {
    func emojiPicker(isPresented: Binding<Bool>, selectedEmoji: Binding<Emoji?>) -> some View {
        modifier(EmojiPickerViewModifier(isPresented: isPresented, selectedEmoji: selectedEmoji))
    }
}

struct EmojiPickerViewModifier: ViewModifier {
    @Binding var isPresented: Bool
    @Binding var selectedEmoji: Emoji?

    private let configuration = ElegantConfiguration(
        showRandom: false,
        showReset: false,
        showClose: false,
        supportsPreview: false
    )

    private let localization = ElegantLocalization(
        searchFieldPlaceholder: MailResourcesStrings.Localizable.searchAction,
        searchResultsTitle: MailResourcesStrings.Localizable.emojiPickerResultsTitle,
        searchResultsEmptyTitle: MailResourcesStrings.Localizable.emptyStateSearchTitle,
        emojiCategoryTitles: [
            .RecentlyUsed: MailResourcesStrings.Localizable.emojiPickerCategoryRecentlyUsed,
            .SmileysAndEmotion: MailResourcesStrings.Localizable.emojiPickerCategorySmileysAndEmotion,
            .PeopleAndBody: MailResourcesStrings.Localizable.emojiPickerCategoryPeopleAndBody,
            .AnimalsAndNature: MailResourcesStrings.Localizable.emojiPickerCategoryAnimalsAndNature,
            .FoodAndDrink: MailResourcesStrings.Localizable.emojiPickerCategoryFoodAndDrink,
            .TravelAndPlaces: MailResourcesStrings.Localizable.emojiPickerCategoryTravelAndPlaces,
            .Activities: MailResourcesStrings.Localizable.emojiPickerCategoryActivities,
            .Objects: MailResourcesStrings.Localizable.emojiPickerCategoryObjects,
            .Symbols: MailResourcesStrings.Localizable.emojiPickerCategorySymbols,
            .Flags: MailResourcesStrings.Localizable.emojiPickerCategoryFlags
        ]
    )

    private var minSize: CGFloat? {
        @InjectService var platformDetector: PlatformDetectable
        if platformDetector.isMacCatalyst {
            return 400
        } else {
            return nil
        }
    }

    private var backgroundColor: Color? {
        @InjectService var platformDetector: PlatformDetectable
        if platformDetector.isMacCatalyst {
            return nil
        } else {
            return MailResourcesAsset.backgroundColor.swiftUIColor
        }
    }

    func body(content: Content) -> some View {
        content
            .popover(isPresented: $isPresented) {
                ElegantEmojiPickerView(
                    selectedEmoji: $selectedEmoji,
                    configuration: configuration,
                    localization: localization,
                    background: backgroundColor,
                    userDefaultsStore: .shared
                )
                .ignoresSafeArea()
                .frame(minWidth: minSize, minHeight: minSize)
                .presentationDetents([.medium, .large])
            }
    }
}
