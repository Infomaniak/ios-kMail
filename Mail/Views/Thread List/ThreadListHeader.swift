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

import Combine
import DesignSystem
import InfomaniakCore
import InfomaniakCoreCommonUI
import InfomaniakCoreSwiftUI
import InfomaniakDI
import MailCore
import MailCoreUI
import MailResources
import OSLog
import RealmSwift
import SwiftUI

class ThreadListHeaderFolderObserver: ObservableObject {
    private let timer = Timer.publish(
        every: 60, // second
        on: .main,
        in: .common
    ).autoconnect()
    private var timerObservation: AnyCancellable?
    // periphery:ignore - We need to keep a reference to this to keep receiving events (automatically removed on deinit)
    private var folderObservation: NotificationToken?

    @Published private(set) var lastUpdateText: String?
    @Published private(set) var unreadCount: Int

    init(folder: Folder) {
        assert(folder.isFrozen, "Folder should always be frozen")

        lastUpdateText = ThreadListHeaderFolderObserver.formatLastUpdate(date: folder.lastUpdate)
        unreadCount = folder.unreadCount

        timerObservation = timer
            .receive(on: DispatchQueue.global(qos: .default))
            .sink { [weak self] _ in
                guard let updatedFolder = folder.thaw(),
                      let lastUpdate = updatedFolder.lastUpdate else {
                    return
                }
                Task { @MainActor in
                    withAnimation {
                        self?.lastUpdateText = ThreadListHeaderFolderObserver.formatLastUpdate(date: lastUpdate)
                    }
                }
            }

        folderObservation = folder.observe(keyPaths: [\Folder.lastUpdate, \Folder.unreadCount], on: .main) { [weak self] change in
            switch change {
            case .change(let folder, _):
                withAnimation {
                    self?.lastUpdateText = ThreadListHeaderFolderObserver.formatLastUpdate(date: folder.lastUpdate)
                    self?.unreadCount = folder.unreadCount
                }
            default:
                break
            }
        }
    }

    static func formatLastUpdate(date: Date?) -> String? {
        var dateToUse = date
        if let interval = date?.timeIntervalSinceNow, interval > -60 {
            // Last update less than 60 seconds ago
            dateToUse = Date()
        }
        return dateToUse?.formatted(Date.RelativeFormatStyle(presentation: .named, capitalizationContext: .middleOfSentence))
    }
}

struct ThreadListHeader: View {
    @LazyInjectService private var matomo: MatomoUtils

    @EnvironmentObject private var mailboxManager: MailboxManager

    @AppStorage(UserDefaults.shared.key(.accentColor)) private var accentColor = DefaultPreferences.accentColor

    @State private var showNoMailServersAvailableView: Bool
    @StateObject private var folderObserver: ThreadListHeaderFolderObserver

    @ObservedObject private var networkMonitor = NetworkMonitor.shared

    let isMultipleSelectionEnabled: Bool

    @Binding var unreadFilterOn: Bool
    private var isRefreshing: Bool

    init(isMultipleSelectionEnabled: Bool,
         folder: Folder,
         unreadFilterOn: Binding<Bool>,
         isRefreshing: Bool) {
        self.isMultipleSelectionEnabled = isMultipleSelectionEnabled
        _unreadFilterOn = unreadFilterOn
        _showNoMailServersAvailableView = State(initialValue: false)
        self.isRefreshing = isRefreshing
        _folderObserver = StateObject(wrappedValue: ThreadListHeaderFolderObserver(folder: folder))
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                if !networkMonitor.isConnected {
                    NoNetworkView()
                }

                if isRefreshing {
                    HStack(spacing: IKPadding.mini) {
                        ProgressView()
                            .controlSize(.small)
                        Text(MailResourcesStrings.Localizable.threadListHeaderUpdating)
                            .textStyle(.bodySmallSecondary)
                    }
                } else {
                    if showNoMailServersAvailableView {
                        NoMailServersAvailableView()
                    } else if let lastUpdateText = folderObserver.lastUpdateText {
                        Text(MailResourcesStrings.Localizable.threadListHeaderLastUpdate(lastUpdateText))
                            .textStyle(.bodySmallSecondary)
                    }
                }
            }
            .onChange(of: isRefreshing) { _ in
                checkMailApiAvailability()
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if folderObserver.unreadCount > 0 && !isMultipleSelectionEnabled {
                Toggle(isOn: $unreadFilterOn) {
                    Text(MailResourcesStrings.Localizable
                        .threadListHeaderUnreadCount(folderObserver.unreadCount.formatted(.indicatorCappedCount)))
                }
                .toggleStyle(.unread)
                .onChange(of: unreadFilterOn) { newValue in
                    if newValue {
                        matomo.track(eventWithCategory: .threadList, name: "unreadFilter")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding(.top, value: .mini)
        .padding(.bottom, value: .small)
        .padding([.leading, .trailing], value: .medium)
        .background(accentColor.navBarBackground.swiftUIColor)
    }

    private func checkMailApiAvailability() {
        Task {
            do {
                try await mailboxManager.apiFetcher.checkAPIStatus()
                showNoMailServersAvailableView = false
            } catch {
                if networkMonitor.isConnected {
                    showNoMailServersAvailableView = true
                }
            }
        }
    }
}

struct UnreadToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack(spacing: IKPadding.mini) {
                configuration.label
                if configuration.isOn {
                    MailResourcesAsset.close
                        .iconSize(.small)
                }
            }
            .textStyle(configuration.isOn ? .bodySmallMediumOnAccent : .bodySmallMediumAccent)
            .padding(.vertical, IKPadding.micro)
            .padding(.horizontal, IKPadding.mini)
            .background(
                Capsule()
                    .fill(configuration.isOn ? Color.accentColor : MailResourcesAsset.backgroundColor.swiftUIColor)
            )
        }
    }
}

extension ToggleStyle where Self == UnreadToggleStyle {
    static var unread: UnreadToggleStyle { .init() }
}

#Preview {
    ThreadListHeader(isMultipleSelectionEnabled: false,
                     folder: PreviewHelper.sampleFolder,
                     unreadFilterOn: .constant(false),
                     isRefreshing: false)
}

#Preview {
    ThreadListHeader(isMultipleSelectionEnabled: false,
                     folder: PreviewHelper.sampleFolder,
                     unreadFilterOn: .constant(true),
                     isRefreshing: false)
}
