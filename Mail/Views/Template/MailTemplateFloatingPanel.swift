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

import Foundation
import MailCore
import SwiftUI

extension View {
    func mailTemplateFloatingPanel(
        isPresented: Binding<Bool>,
    ) -> some View {
        modifier(
            MailTemplateFloatingPanel(
                isShowingFloatingPanel: isPresented
            )
        )
    }
}

struct MailTemplateFloatingPanel: ViewModifier {
    @Binding var isShowingFloatingPanel: Bool

    @State private var title = "Model"
    @State private var templates: [MailTemplate] = []

    func body(content: Content) -> some View {
        content
            .mailFloatingPanel(isPresented: $isShowingFloatingPanel, title: title) {
                VStack(spacing: 8) {
                    ForEach(templates) { template in
                        Text(template.displayName)
                    }
                }
                .task {
                    do {
                        templates = try await MailApiFetcher().mailTemplate()
                    } catch {
                        // handle error
                    }
                }
            }
    }
}
