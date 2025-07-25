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

import InfomaniakCoreSwiftUI
import MailResources
import SwiftUI

enum ReactionSelectionType: Identifiable, Hashable {
    case all
    case reaction(UIMessageReaction)

    var id: Int { hashValue }
}

@available(iOS 16.0, *)
struct ReactionsDetailsView: View {
    @State private var selectedReaction: ReactionSelectionType?
    @State private var currentDetent = PresentationDetent.medium

    private let reactions: [UIMessageReaction]

    init(reactions: [UIMessageReaction], initialSelection: ReactionSelectionType? = nil) {
        _selectedReaction = State(wrappedValue: initialSelection ?? .all)
        self.reactions = reactions
    }

    var body: some View {
        IKFloatingPanelView(
            currentDetent: $currentDetent,
            title: MailResourcesStrings.Localizable.reactionsTitle,
            bottomPadding: 0,
            detents: Set([.medium, .large]),
            dragIndicator: .visible
        ) {
            VStack(spacing: 0) {
                ReactionsDetailsButtonsView(currentSelection: $selectedReaction, reactions: reactions)
                ReactionsListTabView(selectedReaction: $selectedReaction, reactions: reactions)
            }
        }
    }
}

@available(iOS, introduced: 15, deprecated: 16, message: "Use native way")
struct ReactionsDetailsBackportView: View {
    @State private var selectedReaction: ReactionSelectionType? = .all

    let reactions: [UIMessageReaction]
    var initialSelection: ReactionSelectionType?

    var body: some View {
        IKFloatingPanelBackportView(
            title: MailResourcesStrings.Localizable.reactionsTitle,
            bottomPadding: 0,
            detents: Set([.medium, .large]),
            dragIndicator: .visible
        ) {
            VStack(spacing: 0) {
                ReactionsDetailsButtonsView(currentSelection: $selectedReaction, reactions: reactions)
                ReactionsListTabView(selectedReaction: $selectedReaction, reactions: reactions)
            }
            .onAppear {
                if let initialSelection {
                    selectedReaction = initialSelection
                }
            }
        }
    }
}

@available(iOS 16.0, *)
#Preview {
    ReactionsDetailsView(reactions: PreviewHelper.uiReactions)
}
