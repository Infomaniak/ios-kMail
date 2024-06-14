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

import Contacts
import Foundation
import InfomaniakCore
import InfomaniakDI
import Nuke
import RealmSwift
import SwiftUI
import UIKit

extension CNContact {
    static func fromUUID(_ identifier: String) -> CNContact? {
        @InjectService var localContactsHelper: LocalContactsHelpable
        return try? localContactsHelper.getContact(with: identifier)
    }

    func pngImageData() -> Data? {
        // We have to load something that Nuke can cache
        guard let imageData,
              let convertedImage = UIImage(data: imageData)?.pngData() else {
            return nil
        }
        return convertedImage
    }
}

public final class MergedContact: Object, Identifiable {
    private static let contactFormatter = CNContactFormatter()

    /// Shared
    @Persisted(primaryKey: true) public var id: String
    @Persisted public var email: String
    @Persisted public var name: String

    /// Remote
    @Persisted public var remoteColorHex: String?
    @Persisted public var remoteAvatarURL: String?
    @Persisted public var remoteIdentifier: String?

    /// Local
    @Persisted public var localIdentifier: String?

    /// `true` if a remote Infomaniak contact was used to create this object
    public lazy var isRemote = {
        guard remoteIdentifier != nil else {
            return false
        }
        return true
    }()

    /// `true` if a local iPhone contact was used to create this object
    public lazy var isLocal = {
        guard localIdentifier != nil else {
            return false
        }
        return true
    }()

    public lazy var color: UIColor = {
        guard let remoteColorHex,
              let colorFromHex = UIColor(hex: remoteColorHex) else {
            return UIColor.backgroundColor(from: email.hash, with: UIConstants.avatarColors)
        }

        return colorFromHex
    }()

    public var avatarImageRequest: ImageRequest? {
        // iOS Avatar
        if let localIdentifier,
           !localIdentifier.isEmpty,
           let localContact = CNContact.fromUUID(localIdentifier),
           localContact.imageDataAvailable {
            var imageRequest = ImageRequest(id: localIdentifier) {
                guard let imageData = localContact.pngImageData() else {
                    throw MailError.unknownError
                }

                return imageData
            }
            imageRequest.options = [.disableDiskCache]
            return imageRequest
        }

        // IK avatar
        else if let remoteAvatarURL, !remoteAvatarURL.isEmpty {
            let avatarURL = Endpoint.resource(remoteAvatarURL).url
            return ImageRequest(url: avatarURL)
        }

        // nothing
        return nil
    }

    /// Do not use directly
    override public init() { /* Realm needs an empty constructor */ }

    /// Init with what you have, it will generate the most usable contact possible
    public init(email: String, local: CNContact?, remote: InfomaniakContact?) {
        super.init()

        self.email = email

        // Load the object, prefer data from Device
        populateWithRemote(remote)
        overrideWithLocal(local)

        id = MergedContact.computeId(email: email, name: name)
    }

    /// Overload object with local information
    private func overrideWithLocal(_ contact: CNContact?) {
        guard let contact else {
            return
        }

        name = Self.contactFormatter.string(from: contact) ?? ""
        localIdentifier = contact.identifier
    }

    /// IK has _not_ priority over local contacts
    private func populateWithRemote(_ contact: InfomaniakContact?) {
        guard let contact else {
            return
        }

        if let remoteName = contact.name {
            name = remoteName
        }
        remoteColorHex = contact.color
        remoteAvatarURL = contact.avatar
        remoteIdentifier = contact.id
    }

    static func computeId(email: String, name: String?) -> String {
        guard let name, email != name && !name.isEmpty else { return email }
        return name + email
    }
}
