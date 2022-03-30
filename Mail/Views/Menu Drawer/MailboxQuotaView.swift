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
    var mailboxManager: MailboxManager
    var formatter: ByteCountFormatter = {
        let byteCountFormatter = ByteCountFormatter()
        byteCountFormatter.countStyle = .file
        byteCountFormatter.includesUnit = true
        return byteCountFormatter
    }()

    @State private var quotas: Quotas?

    var body: some View {
        HStack {
            ProgressView(value: computeProgression())
                .progressViewStyle(QuotaCircularProgressViewStyle())
                .padding(.trailing, 7)

            VStack(alignment: .leading) {
                HStack {
                    Text("\(formatter.string(from: .init(value: Double(quotas?.size ?? 0), unit: .kilobytes))) / \(formatter.string(from: .init(value: Double(Constants.sizeLimit), unit: .kilobytes)))")
                        .font(.system(size: 18))
                    Text("utilisés")
                }
                Button {
                    print("Todo")
                } label: {
                    Text("Obtenir plus de stockage")
                        .bold()
                }
                .foregroundColor(Color(InfomaniakCoreAsset.infomaniakColor.color))
                .font(.system(size: 15))
            }

            Spacer()
        }
        .onAppear {
            Task {
                do {
                    quotas = try await mailboxManager.apiFetcher.quotas(mailbox: mailboxManager.mailbox)
                } catch {
                    print("Error while fetching quotas: \(error)")
                }
            }
        }
    }

    private func computeProgression() -> Double {
        let value = Double(quotas?.size ?? 0) / Double(Constants.sizeLimit)
        return value > 0.03 ? value : 0.03
    }
}

private struct QuotaCircularProgressViewStyle: ProgressViewStyle {
    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            Circle()
                .trim(from: 0, to: CGFloat(1 - (configuration.fractionCompleted ?? 0)))
                .stroke(Color(InfomaniakCoreAsset.infomaniakColor.color), lineWidth: 2)
                .rotationEffect(.degrees(-90))
                .frame(width: 40)

            Circle()
                .trim(from: CGFloat(1 - (configuration.fractionCompleted ?? 0)), to: 1)
                .stroke(Color(MailResourcesAsset.mailPink.color), lineWidth: 2)
                .rotationEffect(.degrees(-90))
                .frame(width: 40)

            Image(systemName: "tray")
                .foregroundColor(.blue)
        }
        .frame(height: 40)
    }
}
