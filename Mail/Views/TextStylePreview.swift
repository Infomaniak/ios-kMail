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

struct TextStylePreview: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 8) {
                Group {
                    Text("Header 1")
                        .textStyle(.header1)
                    Text("Header 2")
                        .textStyle(.header2)
                    Text("Body")
                        .textStyle(.body)
                    Text("Body secondary")
                        .textStyle(.bodySecondary)
                    Text("Body small")
                        .textStyle(.bodySmall)
                }
                Group {
                    Text("Body medium accent")
                        .textStyle(.bodyMediumAccent)
                    Text("Body medium on accent")
                        .padding()
                        .background(Color.accentColor)
                        .cornerRadius(50)
                        .textStyle(.bodyMediumOnAccent)
                }
            }
            .navigationTitle("Text styles")
        }
    }
}

#Preview {
    TextStylePreview()
}
