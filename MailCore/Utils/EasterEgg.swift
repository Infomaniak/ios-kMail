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

import Foundation
import InfomaniakCoreUI
import InfomaniakDI
import Sentry

public struct EasterEgg {
    public let shouldTrigger: () -> Bool
    public let onTrigger: () -> Void

    public static let halloween = EasterEgg {
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.day, .month], from: Date())
        guard let month = components.month,
              let day = components.day else {
            return false
        }

        return (month == 10 && day >= 25) || (month == 11 && day <= 3)
    } onTrigger: {
        SentrySDK.capture(message: "Easter egg Halloween has been triggered! Woohoo!")

        let year = Calendar(identifier: .gregorian).component(.year, from: Date())
        @InjectService var matomoUtils: MatomoUtils
        matomoUtils.track(eventWithCategory: .easterEgg, name: "halloween\(year)")
    }

    public static let christmas = EasterEgg {
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.day, .month], from: Date())
        guard let month = components.month, let day = components.day else {
            return false
        }

        return month == 12 && day <= 25
    } onTrigger: {
        let year = Calendar(identifier: .gregorian).component(.year, from: Date())
        @InjectService var matomoUtils: MatomoUtils
        matomoUtils.track(eventWithCategory: .easterEgg, name: "XMas\(year)")
    }
}
