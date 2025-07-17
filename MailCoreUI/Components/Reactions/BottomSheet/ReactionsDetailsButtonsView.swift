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

import MailResources
import SwiftUI

struct ReactionsDetailsButtonsView: View {
    @Namespace private var animation

    @Binding var currentSelection: ReactionSelectionType?

    let reactions: [UIMessageReaction]

    var body: some View {
        ZStack(alignment: .bottom) {
            Rectangle()
                .fill(MailResourcesAsset.elementsColor.swiftUIColor)
                .frame(height: 1)

            ScrollViewReader { proxy in
                ScrollView(.horizontal) {
                    HStack {
                        ReactionsDetailsButton(currentSelection: $currentSelection, selectionType: .all, namespace: animation)
                            .id(ReactionSelectionType.all)
                        ForEach(reactions) { reaction in
                            ReactionsDetailsButton(
                                currentSelection: $currentSelection,
                                selectionType: .reaction(reaction),
                                namespace: animation
                            )
                            .id(ReactionSelectionType.reaction(reaction))
                        }
                    }
                    .padding(.horizontal, value: .micro)
                }
                .onChange(of: currentSelection) { newValue in
                    withAnimation(.default) {
                        proxy.scrollTo(newValue)
                    }
                }
            }
        }
    }
}

#Preview {
    ReactionsDetailsButtonsView(currentSelection: .constant(.all), reactions: PreviewHelper.uiReactions)
}
