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

import DesignSystem
import MailResources
import SwiftUI

struct AIProgressView: View {
    var body: some View {
        VStack(spacing: IKPadding.small) {
            ProgressView()
                .controlSize(.large)

            if #available(iOS 26.0, *) {
                Text(MailResourcesStrings.Localizable.aiPromptGenerationLoader)
                    .textStyle(.bodyMediumTertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 64)
        .padding(.bottom, value: .huge)
        .background {
            Rectangle()
                .fill(
                    LinearGradient(
                        stops: [
                            Gradient.Stop(color: MailResourcesAsset.backgroundColor.swiftUIColor, location: 0),
                            Gradient.Stop(
                                color: MailResourcesAsset.backgroundColor.swiftUIColor.opacity(0.75),
                                location: 0.66
                            ),
                            Gradient.Stop(color: .clear, location: 1)
                        ],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
        }
        .allowsHitTesting(false)
    }
}

#Preview {
    AIProgressView()
}
