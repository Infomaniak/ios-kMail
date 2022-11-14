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

import InfomaniakCore
import MailCore
import MailResources
import SwiftUI

struct MailboxQuotaView: View {
    @EnvironmentObject var globalSheet: GlobalBottomSheet

    let quotas: Quotas
    var progressString: AttributedString {
        let localizedText = MailResourcesStrings.Localizable.menuDrawerMailboxStorage(
            Int64(quotas.size * 1000).formatted(.defaultByteCount),
            Constants.sizeLimit.formatted(.defaultByteCount)
        )

        var attributedString = AttributedString(localizedText)
        if let lastWord = localizedText.split(separator: " ").last, let range = attributedString.range(of: lastWord) {
            attributedString[range].font = MailTextStyle.header3.font
        }

        return attributedString
    }

    var body: some View {
        HStack {
            ProgressView(value: quotas.progression)
                .progressViewStyle(QuotaCircularProgressViewStyle())
                .padding(.trailing, 7)

            VStack(alignment: .leading, spacing: 6) {
                Text(progressString)
                    .textStyle(.header5)
            }

            Spacer()
        }
        .padding(.vertical, 19)
        .padding(.horizontal, Constants.menuDrawerHorizontalPadding)
    }
}

private struct QuotaCircularProgressViewStyle: ProgressViewStyle {
    @AppStorage(UserDefaults.shared.key(.accentColor)) private var accentColor = AccentColor.pink

    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            Circle()
                .trim(from: 0, to: 1)
                .stroke(MailResourcesAsset.progressCircleColor.swiftUiColor, lineWidth: 4)
                .rotationEffect(.degrees(-90))
                .frame(width: 46)

            Circle()
                .trim(from: 0, to: configuration.fractionCompleted ?? 0)
                .stroke(Color.accentColor, lineWidth: 4)
                .rotationEffect(.degrees(-90))
                .frame(width: 46)

            Image(resource: MailResourcesAsset.drawer)
                .resizable()
                .scaledToFit()
                .frame(width: 18)
                .foregroundColor(.accentColor)
        }
        .frame(height: 42)
    }
}
