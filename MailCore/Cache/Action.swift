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
import MailResources
import SwiftUI

public struct Action: Identifiable, Hashable, Equatable {
    public var id: Int {
        return hashValue
    }

    public let title: String
    public let shortTitle: String?
    public let floatingPanelIconName: String
    public var floatingPanelIcon: Image {
        return Image(floatingPanelIconName)
    }

    public let matomoName: String?

    init(title: String, shortTitle: String? = nil, icon: MailResourcesImages, matomoName: String?) {
        self.title = title
        self.shortTitle = shortTitle
        floatingPanelIconName = icon.name
        self.matomoName = matomoName
    }
}
