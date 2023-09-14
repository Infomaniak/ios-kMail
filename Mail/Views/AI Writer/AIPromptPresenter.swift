//
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

import SwiftUI

extension View {
    func aiPromptPresenter<ModalContent: View>(isPresenter: Binding<Bool>, @ViewBuilder modalContent: @escaping () -> ModalContent) -> some View {
        modifier(AIPromptPresenter(isPresented: isPresenter, modalContent: modalContent))
    }
}

struct AIPromptPresenter<ModalContent: View>: ViewModifier {
    @Environment(\.isCompactWindow) private var isCompactWindow

    @Binding var isPresented: Bool

    @ViewBuilder let modalContent: () -> ModalContent

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: Binding(get: {
                guard isCompactWindow else { return false }
                return isPresented
            }, set: { newValue in
                isPresented = newValue
            })) {
                if #available(iOS 16.0, *) {
                    modalContent()
                        .modifier(SelfSizingPanelViewModifier(dragIndicator: .hidden))
                } else {
                    modalContent()
                        .modifier(SelfSizingPanelBackportViewModifier(dragIndicator: .hidden))
                }
            }
            .customAlert(isPresented: Binding(get: {
                guard !isCompactWindow else { return false }
                return isPresented
            }, set: { newValue in
                isPresented = newValue
            })) {
                modalContent()
            }
    }
}
