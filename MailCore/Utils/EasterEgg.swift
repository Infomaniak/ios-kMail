/*
 Infomaniak Mail - iOS App
 Copyright (C) 2022 Infomaniak Network SA

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

import Foundation
import InfomaniakCoreCommonUI
import InfomaniakDI

public struct EasterEgg {
    public let shouldTrigger: (LocalPack?, Bool) -> Bool
    public let onTrigger: () -> Void

    public static let christmas = EasterEgg { localPack, isStaff in
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.day, .month], from: Date())
        guard let month = components.month, let day = components.day else {
            return false
        }

        let isCorrectPeriod = month == 12 && day <= 25
        guard isCorrectPeriod else {
            return false
        }

        // We only display for individual users not the business ones
        let allowedPacks: Set<LocalPack> = [.myKSuiteFree, .myKSuitePlus, .starterPack]
        guard allowedPacks.contains(localPack ?? .kSuitePaid) || isStaff else {
            return false
        }

        let probability = Double(day) / 25.0
        return Double.random(in: 0 ... 1) < probability
    } onTrigger: {
        let year = Calendar(identifier: .gregorian).component(.year, from: Date())
        @InjectService var matomoUtils: MatomoUtils
        matomoUtils.track(eventWithCategory: .easterEgg, name: "XMas\(year)")
    }
}
