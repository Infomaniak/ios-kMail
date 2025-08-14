//
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

import SwiftUI

struct ReactionsListTabView: View {
    @Binding var selectedReaction: ReactionSelectionType?

    let reactions: [UIReaction]

    // We need to use a ScrollView because the TabView wrapped inside a sheet is broken.
    // The component struggles to ignore the safe area.
    var body: some View {
        if #available(iOS 17.0, *) {
            ScrollView(.horizontal) {
                LazyHStack(spacing: 0) {
                    ReactionsList(reactions: reactions)
                        .containerRelativeFrame(.horizontal)
                        .id(ReactionSelectionType.all)
                    ForEach(reactions) { reaction in
                        ReactionsList(reaction: reaction)
                            .containerRelativeFrame(.horizontal)
                            .id(ReactionSelectionType.reaction(reaction.emoji))
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: $selectedReaction)
        } else {
            TabView(selection: Binding(get: { selectedReaction ?? .all }, set: { selectedReaction = $0 })) {
                ReactionsList(reactions: reactions)
                    .tag(ReactionSelectionType.all)
                ForEach(reactions) { reaction in
                    ReactionsList(reaction: reaction)
                        .tag(ReactionSelectionType.reaction(reaction.emoji))
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
    }
}

#Preview {
    ReactionsListTabView(selectedReaction: .constant(nil), reactions: PreviewHelper.uiReactions)
}
