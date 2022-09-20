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
import Kingfisher
import RealmSwift
import SwiftUI
import UIKit

public class MergedContact {
    public var email: String
    public var remote: Contact?
    public var local: CNContact?

    private let contactFormatter = CNContactFormatter()

    public lazy var color: String = remote?.color ?? "#00bcd4"

    public lazy var name: String = {
        if let local = local, let localName = contactFormatter.string(from: local) {
            return localName.removePunctuation
        }
        return remote?.name.removePunctuation ?? ""
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

    public func getAvatar(size: CGSize = CGSize(width: 40, height: 40), completion: @escaping (UIImage) -> Void) {
        if let data = local?.imageData, let image = UIImage(data: data) {
            completion(image)
        } else if let avatarPath = remote?.avatar {
            KingfisherManager.shared.retrieveImage(with: Endpoint.resource(avatarPath).url) { result in
                if let avatarImage = try? result.get().image {
                    completion(avatarImage)
                }
            }
        } else {
            let backgroundColor = UIColor(hex: color)!
            completion(UIImage.getInitialsPlaceholder(with: name, size: size, backgroundColor: backgroundColor))
        }
    }

    private func merge<T>(_ element1: T?, _ element2: T?) -> T? {
        return element1 ?? element2
    }

    public init(email: String, remote: Contact?, local: CNContact?) {
        self.email = email
        self.remote = remote
        self.local = local
    }
}
