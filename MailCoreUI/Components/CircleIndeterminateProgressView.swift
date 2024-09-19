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

import SwiftUI

public struct CircleIndeterminateProgressView: View {
    let progress: Double

    public init(progress: Double) {
        self.progress = progress
    }

    public var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 2)
                .opacity(0.1)
                .foregroundColor(Color.gray)
                .frame(height: 15)

            Circle()
                .trim(from: 0.0, to: min(progress, 1.0))
                .stroke(style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                .foregroundColor(Color.accentColor)
                .rotationEffect(Angle(degrees: 270.0))
                .animation(.linear, value: progress)
                .frame(height: 15)
        }
    }
}

#Preview {
    CircleIndeterminateProgressView(progress: 1)
}
