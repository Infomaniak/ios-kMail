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
    func pngImageData() async -> Data? {
        // We have to load something that Nuke can cache
        guard let imageData,
              let convertedImage = UIImage(data: imageData)?.pngData() else {
            return nil
        }
        return convertedImage
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
            return UIColor.backgroundColor(from: email.hash, with: UIConstants.avatarColors)
        }
    }()

    public lazy var name: String = {
        if let local = local, let localName = contactFormatter.string(from: local) {
            return localName
        }
        return remote?.name ?? ""
    }()

    public var isLocal: Bool {
        return local != nil
    }

    public var isInfomaniak: Bool {
        return remote != nil
    }

    public init(email: String, remote: Contact?, local: CNContact?) {
        self.email = email
        self.remote = remote
        self.local = local
    }
}

extension MergedContact: AvatarDisplayable {
    public var avatarImageRequest: ImageRequest? {
        if let localContact = local, localContact.imageDataAvailable {
            var imageRequest = ImageRequest(id: localContact.identifier) {
                guard let imageData = await localContact.pngImageData() else {
                    throw MailError.unknownError
                }

                return imageData
            }
            imageRequest.options = [.disableDiskCache]
            return imageRequest
        }

        if let remoteAvatar = remote?.avatar {
            let avatarURL = Endpoint.resource(remoteAvatar).url
            return AccountManager.instance.currentMailboxManager?.apiFetcher.authenticatedImageRequest(avatarURL)
        }

        return nil
    }

    public var initials: String {
        ""
    }

    public var initialsBackgroundColor: UIColor {
        color
    }
}
