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

import InfomaniakCore
import MailCore
import MailCoreUI
import MailResources
import SwiftUI

struct MailboxQuotaView: View {
    let quotas: Quotas

    private var progressString: String {
        return MailResourcesStrings.Localizable.menuDrawerMailboxStorage(
            Int64(quotas.size * 1000).formatted(.defaultByteCount),
            Constants.sizeLimit.formatted(.defaultByteCount)
        )
    }

    var body: some View {
        HStack(spacing: UIPadding.menuDrawerCellSpacing) {
            ProgressView(value: quotas.progression)
                .progressViewStyle(QuotaCircularProgressViewStyle())

            Text(progressString)
                .textStyle(.bodyMedium)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(UIPadding.menuDrawerCell)
    }
}

private struct QuotaCircularProgressViewStyle: ProgressViewStyle {
    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            Circle()
                .trim(from: 0, to: 1)
                .stroke(MailResourcesAsset.elementsColor.swiftUIColor, lineWidth: 4)
                .rotationEffect(.degrees(-90))
                .frame(width: UIConstants.menuDrawerQuotaSize)

            Circle()
                .trim(from: 0, to: configuration.fractionCompleted ?? 0)
                .stroke(Color.accentColor, lineWidth: 4)
                .rotationEffect(.degrees(-90))
                .frame(width: UIConstants.menuDrawerQuotaSize)

            IKIcon(MailResourcesAsset.drawer)
                .foregroundStyle(.tint)
        }
        .frame(height: UIConstants.menuDrawerQuotaSize)
    }
}

#Preview {
    MailboxQuotaView(quotas: Quotas())
}
