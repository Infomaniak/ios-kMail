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
import InfomaniakCoreSwiftUI
import InfomaniakCoreUIResources
import InfomaniakRichHTMLEditor
import MailCore
import MailCoreUI
import MailResources
import PhotosUI
import SwiftModalPresentation
import SwiftUI

struct EditorMobileToolbarView: View {
    private static let baseAnimation = Animation.default.speed(1.75)
    static let appearAnimation = Self.baseAnimation.delay(0.1)
    static let disappearAnimation = Self.baseAnimation

    @State private var isShowingClassicOptions = true
    @State private var isShowingFormattingOptions = false

    @ObservedObject var textAttributes: TextAttributes

    @Binding var isShowingAI: Bool

    let draft: Draft

    private let transition = AnyTransition.opacity.combined(with: .move(edge: .bottom))

    var body: some View {
        ZStack {
            if isShowingClassicOptions {
                MobileClassicToolbarView(
                    isShowingClassicOptions: $isShowingClassicOptions,
                    isShowingFormattingOptions: $isShowingFormattingOptions,
                    isShowingAI: $isShowingAI,
                    draft: draft
                )
                .transition(transition)
            }

            if isShowingFormattingOptions {
                MobileFormattingToolbarView(
                    textAttributes: textAttributes,
                    isShowingClassicOptions: $isShowingClassicOptions,
                    isShowingFormattingOptions: $isShowingFormattingOptions
                )
                .transition(transition)
            }
        }
        .padding(.vertical, value: .mini)
        .padding(.horizontal, value: .medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: IKIconSize.large.rawValue + IKPadding.mini * 2)
        .background(MailResourcesAsset.backgroundColor.swiftUIColor)
    }
}

#Preview {
    EditorMobileToolbarView(
        textAttributes: TextAttributes(),
        isShowingAI: .constant(false),
        draft: Draft()
    )
}
