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
import Kingfisher
import RealmSwift
import SwiftUI
import UIKit

public class MergedContact: Object, Identifiable {
    @Persisted(primaryKey: true) public var email: String = UUID().uuidString
    @Persisted public var remote: Contact?
    @Persisted public var localId: String?

    private let contactFormatter = CNContactFormatter()

    private lazy var local: CNContact? = {
        if let localId = localId {
            Task {
                try await LocalContactsHelper.shared.getContact(with: localId)
            }
        }
        return nil
    }()

    public lazy var color: String = remote?.color ?? "#00bcd4"
    public lazy var firstname: String = merge(local?.givenName, remote?.firstname) ?? ""
    public lazy var lastName: String = merge(local?.familyName, remote?.lastname) ?? ""

    public lazy var name: String = {
        if let local = local, let localName = contactFormatter.string(from: local) {
            return localName
        }
        return remote?.name ?? ""
    }()

    public lazy var favorite: Bool? = remote?.favorite
    public lazy var nickname: String? = merge(local?.nickname, remote?.nickname)
    public lazy var organization: String? = merge(local?.organizationName, remote?.organization)

    public lazy var avatarData: Data? = local?.imageData
    public lazy var avatarPath: String? = remote?.avatar

    public var isLocal: Bool {
        return localId != nil
    }

    public var isInfomaniak: Bool {
        return remote != nil
    }

    public var hasAvatar: Bool {
        return avatarData != nil || remote?.avatar != nil
    }

    func getAvatar(size: CGSize = CGSize(width: 40, height: 40), completion: @escaping (UIImage) -> Void) {
        if let data = avatarData, let image = UIImage(data: data) {
            completion(image)
        } else if let avatarPath = avatarPath, let avatarUrl = URL(string: avatarPath) {
            KingfisherManager.shared.retrieveImage(with: avatarUrl) { result in
                if let avatarImage = try? result.get().image {
                    completion(avatarImage)
                }
            }
        } else {
            let backgroundColor = UIColor(hex: color)!
            completion(UIImage.getInitialsPlaceholder(with: name, size: size, backgroundColor: backgroundColor))
        }
    }

    private static let contactFormatter = CNContactFormatter()

    private func merge<T>(_ element1: T?, _ element2: T?) -> T? {
        return element1 ?? element2
    }

    convenience init(email: String, localId: String?, remote: Contact?) {
        self.init()
        self.email = email
        self.localId = localId
        self.remote = remote
    }
}
