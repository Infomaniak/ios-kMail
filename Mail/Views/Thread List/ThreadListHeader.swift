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
import InfomaniakCore
import InfomaniakCoreUI
import InfomaniakDI
import MailCore
import MailCoreUI
import MailResources
import RealmSwift
import SwiftUI

class ThreadListHeaderFolderObserver: ObservableObject {
    private let timer = Timer.publish(
        every: 60, // second
        on: .main,
        in: .common
    ).autoconnect()
    private var timerObservation: AnyCancellable?
    private var folderObservation: NotificationToken?

    @Published private(set) var lastUpdateText: String?
    @Published private(set) var unreadCount: Int

    init(folder: Folder) {
        lastUpdateText = ThreadListHeaderFolderObserver.formatLastUpdate(date: folder.lastUpdate)
        unreadCount = folder.unreadCount

        timerObservation = timer
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                withAnimation {
                    self?.lastUpdateText = ThreadListHeaderFolderObserver.formatLastUpdate(date: folder.lastUpdate)
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

    @AppStorage(UserDefaults.shared.key(.accentColor)) private var accentColor = DefaultPreferences.accentColor
    @StateObject private var folderObserver: ThreadListHeaderFolderObserver
    @ObservedObject private var networkMonitor = NetworkMonitor.shared

    let isMultipleSelectionEnabled: Bool

    @Binding var unreadFilterOn: Bool

    init(isMultipleSelectionEnabled: Bool,
         folder: Folder,
         unreadFilterOn: Binding<Bool>) {
        self.isMultipleSelectionEnabled = isMultipleSelectionEnabled
        _unreadFilterOn = unreadFilterOn
        _folderObserver = StateObject(wrappedValue: ThreadListHeaderFolderObserver(folder: folder))
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                if !networkMonitor.isConnected {
                    NoNetworkView()
                }
                if let lastUpdateText = folderObserver.lastUpdateText {
                    Text(MailResourcesStrings.Localizable.threadListHeaderLastUpdate(lastUpdateText))
                        .textStyle(.bodySmallSecondary)
                }
            }
            Spacer()
            if folderObserver.unreadCount > 0 && !isMultipleSelectionEnabled {
                Toggle(isOn: $unreadFilterOn) {
                    Text(folderObserver.unreadCount < 100 ? MailResourcesStrings.Localizable
                        .threadListHeaderUnreadCount(folderObserver.unreadCount) : MailResourcesStrings.Localizable
                        .threadListHeaderUnreadCountMore)
                }
                .toggleStyle(.unread)
                .onChange(of: unreadFilterOn) { newValue in
                    if newValue {
                        matomo.track(eventWithCategory: .threadList, name: "unreadFilter")
                    }
                }
            }
        }
        .padding(.top, value: .small)
        .padding([.leading, .trailing, .bottom], value: .regular)
        .background(accentColor.navBarBackground.swiftUIColor)
    }
}

struct UnreadToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack(spacing: 8) {
                configuration.label
                if configuration.isOn {
                    IKIcon(MailResourcesAsset.close, size: .small)
                }
            }
            .textStyle(configuration.isOn ? .bodySmallMediumOnAccent : .bodySmallMediumAccent)
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
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
                     unreadFilterOn: .constant(false))
}

#Preview {
    ThreadListHeader(isMultipleSelectionEnabled: false,
                     folder: PreviewHelper.sampleFolder,
                     unreadFilterOn: .constant(true))
}
