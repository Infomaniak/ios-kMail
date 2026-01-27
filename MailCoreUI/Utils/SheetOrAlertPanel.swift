/*
 Infomaniak Mail - iOS App
 Copyright (C) 2023 Infomaniak Network SA

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
import SwiftUI

public extension View {
    func sheetOrAlertPanel<ModalContent: View>(isPresented: Binding<Bool>,
                                               @ViewBuilder modalContent: @escaping () -> ModalContent) -> some View {
        modifier(SheetOrAlertPanel(isPresented: isPresented, modalContent: modalContent))
    }
}

public struct SheetOrAlertPanel<ModalContent: View>: ViewModifier {
    @Environment(\.isCompactWindow) private var isCompactWindow

    @Binding var isPresented: Bool

    @ViewBuilder let modalContent: () -> ModalContent

    public init(isPresented: Binding<Bool>, modalContent: @escaping () -> ModalContent) {
        _isPresented = isPresented
        self.modalContent = modalContent
    }

    public func body(content: Content) -> some View {
        content
            .sheet(isPresented: Binding(get: { isCompactWindow && isPresented }, set: { isPresented = $0 })) {
                modalContent()
                    .modifier(SelfSizingPanelViewModifier(topPadding: IKPadding.large, bottomPadding: IKPadding.medium))
            }
            .mailCustomAlert(isPresented: Binding(get: { !isCompactWindow && isPresented }, set: { isPresented = $0 })) {
                modalContent()
            }
    }
}
