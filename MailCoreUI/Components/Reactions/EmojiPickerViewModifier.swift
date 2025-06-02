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

    private let emojiPickerConfiguration = ElegantConfiguration(
        showSearch: true,
        showRandom: false,
        showReset: false,
        showClose: false,
        showToolbar: true,
        supportsPreview: false
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
                if #available(iOS 16.0, *) {
                    ElegantEmojiPickerView(
                        selectedEmoji: $selectedEmoji,
                        configuration: emojiPickerConfiguration,
                        background: backgroundColor
                    )
                    .ignoresSafeArea()
                    .frame(minWidth: minSize, minHeight: minSize)
                    .presentationDetents([.medium, .large])
                } else {
                    ElegantEmojiPickerView(
                        selectedEmoji: $selectedEmoji,
                        configuration: emojiPickerConfiguration,
                        background: backgroundColor
                    )
                    .ignoresSafeArea()
                    .frame(minWidth: minSize, minHeight: minSize)
                    .backport.presentationDetents([.medium, .large])
                }
            }
    }
}
