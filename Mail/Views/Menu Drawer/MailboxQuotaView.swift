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
    @EnvironmentObject var mailboxManager: MailboxManager

    @State private var quotas: Quotas?

    var body: some View {
        HStack {
            ProgressView(value: computeProgression())
                .progressViewStyle(QuotaCircularProgressViewStyle())
                .padding(.trailing, 7)

            VStack(alignment: .leading) {
                Text(MailResourcesStrings.Localizable.menuDrawerMailboxStorage(
                    Int64((quotas?.size ?? 0) * 1000).formatted(.defaultByteCount),
                    Constants.sizeLimit.formatted(.defaultByteCount)
                ))
                .textStyle(.header3)

                Button(action: openGetMoreStorage) {
                    Text(MailResourcesStrings.Localizable.buttonMoreStorage)
                }
                .textStyle(.button)
            }

            Spacer()
        }
        .padding(.vertical, 19)
        .padding(.horizontal, Constants.menuDrawerHorizontalPadding)
        .task {
            do {
                quotas = try await mailboxManager.apiFetcher.quotas(mailbox: mailboxManager.mailbox)
            } catch {
                print("Error while fetching quotas: \(error)")
            }
        }
    }

    // MARK: - Private functions

    private func computeProgression() -> Double {
        let minimumValue = 0.03
        let value = Double(quotas?.size ?? 0) / Double(Constants.sizeLimit)
        return value > minimumValue ? value : minimumValue
    }

    private func openGetMoreStorage() {
        // TODO: Open "Get More Storage View"
    }
}

private struct QuotaCircularProgressViewStyle: ProgressViewStyle {
    @AppStorage(UserDefaults.shared.key(.accentColor)) private var accentColor = AccentColor.pink

    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            Circle()
                .trim(from: 0, to: CGFloat(1 - (configuration.fractionCompleted ?? 0)))
                .stroke(accentColor.secondary.swiftUiColor, lineWidth: 2)
                .rotationEffect(.degrees(-90))
                .frame(width: 46)

            Circle()
                .trim(from: CGFloat(1 - (configuration.fractionCompleted ?? 0)), to: 1)
                .stroke(Color.accentColor, lineWidth: 2)
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
