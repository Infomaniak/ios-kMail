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
import InfomaniakCoreUI
import MailCore
import MailResources
import SwiftUI

struct ThreadListHeader: View {
    var isMultipleSelectionEnabled: Bool

    @Binding var isConnected: Bool
    @Binding var lastUpdate: Date?
    @Binding var unreadCount: Int?
    @Binding var unreadFilterOn: Bool

    @State private var lastUpdateText: String?

    let matomo: MatomoUtils

    let timer = Timer.publish(
        every: 60, // second
        on: .main,
        in: .common
    ).autoconnect()

    init(isMultipleSelectionEnabled: Bool,
         isConnected: Binding<Bool>,
         lastUpdate: Binding<Date?>,
         unreadCount: Binding<Int?>,
         unreadFilterOn: Binding<Bool>,
         matomo: MatomoUtils) {
        self.isMultipleSelectionEnabled = isMultipleSelectionEnabled
        self.matomo = matomo
        _isConnected = isConnected
        _lastUpdate = lastUpdate
        _unreadCount = unreadCount
        _unreadFilterOn = unreadFilterOn
        _lastUpdateText = State(initialValue: formatLastUpdate(date: lastUpdate.wrappedValue))
    }

    var body: some View {
        HStack {
            if isConnected {
                if let lastUpdateText = lastUpdateText {
                    Text(MailResourcesStrings.Localizable.threadListHeaderLastUpdate(lastUpdateText))
                        .textStyle(.bodySmallSecondary)
                }
            } else {
                NoNetworkView()
            }
            Spacer()
            if let unreadCount = unreadCount, unreadCount > 0 && !isMultipleSelectionEnabled {
                Toggle(isOn: $unreadFilterOn) {
                    Text(unreadCount < 100 ? MailResourcesStrings.Localizable
                        .threadListHeaderUnreadCount(unreadCount) : MailResourcesStrings.Localizable
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
        .padding(.top, 8)
        .padding([.leading, .trailing, .bottom], 16)
        .background(MailResourcesAsset.backgroundNavBarColor.swiftUiColor)
        .onChange(of: lastUpdate) { newValue in
            lastUpdateText = formatLastUpdate(date: newValue)
        }
        .onChange(of: unreadCount) { newValue in
            if newValue == 0 {
                unreadFilterOn = false
            }
        }
        .onReceive(timer) { _ in
            lastUpdateText = formatLastUpdate(date: lastUpdate)
        }
    }

    func formatLastUpdate(date: Date?) -> String? {
        var dateToUse = date
        if let interval = date?.timeIntervalSinceNow, interval > -60 {
            // Last update less than 60 seconds ago
            dateToUse = Date()
        }
        return dateToUse?.formatted(Date.RelativeFormatStyle(presentation: .named, capitalizationContext: .middleOfSentence))
    }
}

struct UnreadToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack(spacing: 5) {
                configuration.label
                if configuration.isOn {
                    Image(systemName: "xmark")
                }
            }
            .textStyle(configuration.isOn ? .bodySmallMediumOnAccent : .bodySmallMediumAccent)
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(
                Capsule()
                    .fill(configuration.isOn ? Color.accentColor : MailResourcesAsset.backgroundColor.swiftUiColor)
            )
        }
    }
}

extension ToggleStyle where Self == UnreadToggleStyle {
    static var unread: UnreadToggleStyle { .init() }
}

struct ThreadListHeader_Previews: PreviewProvider {
    static var previews: some View {
        ThreadListHeader(isMultipleSelectionEnabled: false,
                         isConnected: .constant(true),
                         lastUpdate: .constant(Date()),
                         unreadCount: .constant(2),
                         unreadFilterOn: .constant(false),
                         matomo: PreviewHelper.sampleMatomo)
        ThreadListHeader(isMultipleSelectionEnabled: false,
                         isConnected: .constant(false),
                         lastUpdate: .constant(nil),
                         unreadCount: .constant(1),
                         unreadFilterOn: .constant(true),
                         matomo: PreviewHelper.sampleMatomo)
    }
}
