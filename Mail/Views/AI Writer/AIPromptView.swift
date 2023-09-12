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

import MailCore
import MailResources
import SwiftUI

struct AIPromptView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var userPrompt = ""

    @FocusState private var textFieldFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: UIPadding.regular) {
            HStack(spacing: UIPadding.regular) {
                AIHeaderView()
                    .frame(maxWidth: .infinity, alignment: .leading)

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .resizable()
                        .frame(width: 16, height: 16)
                        .foregroundColor(MailResourcesAsset.textSecondaryColor)
                }

            }

            TextField(
                "Dites à l’assistant de rédaction ce que vous souhaitez écrire. Par exemple “un mail de remerciement pour un cadeau de bienvenue”.",
                text: $userPrompt
            )
            .focused($textFieldFocused)

            MailButton(label: "Générer") {
                // TODO: j'imagine qu'il faut générer
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(value: .regular)
        .onAppear {
            textFieldFocused = true
        }
    }
}

#Preview {
    AIPromptView()
}
