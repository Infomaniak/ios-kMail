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

import Contacts
import Foundation
import InfomaniakCore
import Nuke
import RealmSwift
import SwiftUI
import UIKit

extension CNContact {
    var image: UIImage? {
        guard let imageData = imageData else { return nil }
        let localImage = UIImage(data: imageData)
        return localImage
    }
}

public class MergedContact {
    public var email: String
    public var remote: Contact?
    public var local: CNContact?

    private let contactFormatter = CNContactFormatter()

    public lazy var color: UIColor = {
        if let remoteColorHex = remote?.color,
           let colorFromHex = UIColor(hex: remoteColorHex) {
            return colorFromHex
        } else {
            return UIColor.backgroundColor(from: email.hash)
        }
    }()

    public lazy var name: String = {
        if let local = local, let localName = contactFormatter.string(from: local) {
            return localName.removePunctuation
        }
        return remote?.name?.removePunctuation ?? ""
    }()

    public var isLocal: Bool {
        return local != nil
    }

    public var isInfomaniak: Bool {
        return remote != nil
    }

    public var hasAvatar: Bool {
        return local?.imageData != nil || remote?.avatar != nil
    }

    public var avatarImage: Image? {
        get async {
            if let localImage = local?.image {
                return Image(uiImage: localImage)
            } else if let avatarPath = remote?.avatar,
                      let avatarUIImage = try? await ImagePipeline.shared.image(for: Endpoint.resource(avatarPath).url).image {
                return Image(uiImage: avatarUIImage)
            }

            return nil
        }
    }

    public var cachedAvatarImage: Image? {
        if let localImage = local?.image {
            return Image(uiImage: localImage)
        } else if let avatarPath = remote?.avatar,
                  let avatarUIImage = ImagePipeline.shared.cache[Endpoint.resource(avatarPath).url]?.image {
            return Image(uiImage: avatarUIImage)
        }

        return nil
    }

    public init(email: String, remote: Contact?, local: CNContact?) {
        self.email = email
        self.remote = remote
        self.local = local
    }
}
