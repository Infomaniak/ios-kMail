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
import RealmSwift
import SwiftUI
import UIKit

struct MenuDrawerView: View {
    @State private var showMailboxes = false

    // swiftlint:disable empty_count
    @ObservedResults(Folder.self, where: { $0.parentLink.count == 0 }) var folders
    private var mailboxManager: MailboxManager
    private weak var splitViewController: UISplitViewController?

    init(mailboxManager: MailboxManager, splitViewController: UISplitViewController) {
        self.mailboxManager = mailboxManager
        // swiftlint:disable empty_count
        _folders = .init(Folder.self, configuration: mailboxManager.realmConfiguration) { $0.parentLink.count == 0 }
        self.splitViewController = splitViewController
    }

    var body: some View {
        VStack {
            MenuHeaderView(splitViewController: splitViewController)

            MailboxesManagementView(mailboxManager: mailboxManager)

            List(AnyRealmCollection(folders), children: \.listChildren) { folder in
                Button {
                    updateSplitView(with: folder)
                } label: {
                    HStack {
                        Image(systemName: "tray")
                            .foregroundColor(Color(InfomaniakCoreAsset.infomaniakColor.color))
                        Text(folder.localizedName)
                        Spacer()
                        if let unreadCount = folder.unreadCount, unreadCount > 0 {
                            Text(unreadCount < 100 ? "\(unreadCount)" : "99+")
                        }
                    }
                }
            }
            .listStyle(.plain)
            .accentColor(Color(InfomaniakCoreAsset.infomaniakColor.color))
            .onAppear {
                Task {
                    await fetchFolders()
                    MatomoUtils.track(view: ["MenuDrawer"])
                }
            }

            MailboxQuotaView(mailboxManager: mailboxManager)
        }
    }

    // MARK: - Private functions

    private func updateSplitView(with folder: Folder) {
        let messageListVC = ThreadListViewController(mailboxManager: mailboxManager, folder: folder)
        splitViewController?.setViewController(messageListVC, for: .supplementary)
    }

    private func fetchFolders() async {
        do {
            try await mailboxManager.folders()
        } catch {
            print("Error while getting folders: \(error.localizedDescription)")
        }
    }

    // MARK: - Menu actions
}

private struct MenuHeaderView: View {
    var splitViewController: UISplitViewController?

    var body: some View {
        HStack {
            Text("Infomaniak Mail")
            Spacer()
            Button {
                splitViewController?.setViewController(SettingsViewController(), for: .secondary)
            } label: {
                Image(systemName: "gearshape")
            }
        }
        .padding()
    }
}

private struct MailboxesManagementView: View {
    @State private var unfoldDetails = false

    var mailboxManager: MailboxManager

    var body: some View {
        DisclosureGroup(isExpanded: $unfoldDetails) {
            VStack(alignment: .leading) {
                ForEach(AccountManager.instance.mailboxes.filter { $0.mailboxId != mailboxManager.mailbox.mailboxId }, id: \.mailboxId) { mailbox in
                    Button {
                        print("Update account")
                    } label: {
                        Text(mailbox.email)
                        Spacer()
                        Text("2")
                    }
                }

                Divider()

                Button("Ajouter un compte") {}
                Button("Gérer mon compte") {}
            }
            .padding(.leading)
        } label: {
            Text(mailboxManager.mailbox.email)
                .bold()
                .lineLimit(1)
        }
        .accentColor(.primary)
        .padding()
    }
}

private struct MailboxQuotaView: View {
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
            ProgressView(value: computeQuotas())
                .progressViewStyle(QuotaCircularProgressViewStyle())

            VStack(alignment: .leading) {
                Text(
                    "\(formatter.string(from: .init(value: Double(quotas?.size ?? 0), unit: .kilobytes))) / \(formatter.string(from: .init(value: Double(Constants.sizeLimit), unit: .kilobytes))) utilisés"
                )
                Button {
                    // TODO: Add action
                } label: {
                    Text("Obtenir plus de stockage")
                        .bold()
                }
            }

            Spacer()
        }
        .onChange(of: quotas, perform: { newValue in
            print(Double(newValue?.size ?? 0) / Double(Constants.sizeLimit))
            print(Double(newValue?.size ?? 0))
            print(Constants.sizeLimit)
        })
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

    private func computeQuotas() -> Double {
        let value = Double(quotas?.size ?? 0) / Double(Constants.sizeLimit)
        return value > 0.03 ? value : 0.03
    }
}

private struct QuotaCircularProgressViewStyle: ProgressViewStyle {
    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            Circle()
                .trim(from: 0, to: CGFloat(1 - (configuration.fractionCompleted ?? 0)))
                .stroke(Color.blue, lineWidth: 2)
                .rotationEffect(.degrees(-90))
                .frame(width: 40)

            Circle()
                .trim(from: CGFloat(1 - (configuration.fractionCompleted ?? 0)), to: 1)
                .stroke(Color.red, lineWidth: 2)
                .rotationEffect(.degrees(-90))
                .frame(width: 40)

            Image(systemName: "tray")
                .foregroundColor(.blue)
        }
        .frame(height: 40)
    }
}
