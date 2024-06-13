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

import SwiftUI

public struct IndeterminateProgressView: View {
    @State private var animationDuration = 1.0

    let indeterminate: Bool
    let progress: Double

    public init(indeterminate: Bool, progress: Double) {
        self.indeterminate = indeterminate
        self.progress = progress
    }

    public var body: some View {
        ZStack {
            ProgressView(value: indeterminate ? 0 : progress)
            if indeterminate {
                Capsule()
                    .fill(Color.accentColor)
                    .frame(height: 4)
                    .opacity(animationDuration)
                    .onAppear {
                        animationDuration = 0
                    }
                    .animation(
                        .easeInOut(duration: 0.75)
                            .repeatForever(),
                        value: animationDuration
                    )
            }
        }
    }
}

#Preview {
    IndeterminateProgressView(indeterminate: true, progress: 1)
        .padding()
}
