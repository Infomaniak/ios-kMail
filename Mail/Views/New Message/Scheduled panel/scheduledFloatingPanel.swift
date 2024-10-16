//
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

import InfomaniakCoreSwiftUI
import MailCoreUI
import MailResources
import SwiftUI

enum ScheduledSendOption: String, Identifiable, CaseIterable {
    case thisAfternoon
    case tomorrowMorning
    case nextWeek
    case personal

    var id: Self { self }

    var date: Date? {
        switch self {
        case .thisAfternoon:
            return dateFromNow(hour: 14, of: (.day, 0))
        case .tomorrowMorning:
            return dateFromNow(hour: 8, of: (.day, 1))
        case .nextWeek:
            return dateFromNow(hour: 8, of: (.weekday, 1))
        default:
            return nil
        }
    }

    var title: String {
        switch self {
        case .thisAfternoon:
            return "thisAfternoon"
        case .tomorrowMorning:
            return "tomorrowMorning"
        case .nextWeek:
            return "nextWeek"
        default:
            return "personaloon:"
        }
    }

    var icon: Image {
        switch self {
        case .thisAfternoon:
            return MailResourcesAsset.todayAfternoon.swiftUIImage
        case .tomorrowMorning:
            return MailResourcesAsset.tomorrowMorning.swiftUIImage
        case .nextWeek:
            return MailResourcesAsset.nextWeek.swiftUIImage
        default:
            return MailResourcesAsset.pencil.swiftUIImage
        }
    }

    private func dateFromNow(hour: Int, of: (Calendar.Component, Int)) -> Date? {
        let calendar = Calendar.current
        if let startDate = calendar.date(byAdding: of.0, value: of.1, to: .now) {
            return calendar.date(bySettingHour: hour, minute: 0, second: 0, of: startDate)
        }
        return nil
    }
}

extension View {
    func scheduledFloatingPanel(isPresented: Binding<Bool>) -> some View {
        modifier(scheduledFloatingPanelModifier(isPresented: isPresented))
    }
}

struct scheduledFloatingPanelModifier: ViewModifier {
    @Binding var isPresented: Bool

    func body(content: Content) -> some View {
        content
            .floatingPanel(isPresented: $isPresented) {
                VStack {
                    Text("Scheduled Send")
                        .font(.title3)
                    ForEach(ScheduledSendOption.allCases) { option in
                        Button(action: { isPresented.toggle() }) {
                            HStack {
                                Label {
                                    Text(option.title)
                                } icon: {
                                    option.icon
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                if let optDate = option.date {
                                    Text(DateFormatter.localizedString(from: optDate, dateStyle: .medium, timeStyle: .short))
                                }
                            }
                        }
                        .padding(.vertical, value: .small)
                        .padding(.horizontal, value: .medium)
                        IKDivider()
                    }
                }
            }
    }
}

#Preview {
    Text("Oui c'est moi")
        .scheduledFloatingPanel(isPresented: .constant(true))
}
