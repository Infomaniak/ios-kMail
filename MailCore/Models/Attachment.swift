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
import PDFKit
import QuickLookThumbnailing
import RealmSwift
import SwiftUI
import UniformTypeIdentifiers

public class Attachment: /* Hashable, */ EmbeddedObject, Codable, Identifiable {
    @Persisted public var uuid: String?
    @Persisted public var partId: String // PROLEM: Sometimes API return a String, sometimes an Int. Check with backend if we can have one type only? -- Asked to Julien A. on 08.09 - To follow up.
    @Persisted public var mimeType: String
    @Persisted public var encoding: String?
    @Persisted public var size: Int
    @Persisted public var name: String
    @Persisted public var disposition: AttachmentDisposition
    @Persisted public var contentId: String?
    @Persisted public var resource: String?
    @Persisted public var driveUrl: String?
    @Persisted public var data: Data? = nil
    public var localUrl: URL? = nil
    public var thumbnail: Image? = nil

    public var uti: UTType? {
        UTType(mimeType: mimeType, conformingTo: .data)
    }

    private enum CodingKeys: String, CodingKey {
        case uuid
        case partId
        case mimeType
        case encoding
        case size
        case name
        case disposition
        case contentId
        case resource
        case driveUrl
    }

    public static func == (lhs: Attachment, rhs: Attachment) -> Bool {
        return lhs.id == rhs.id
    }

    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        uuid = try values.decodeIfPresent(String.self, forKey: .uuid)
        if let partId = try? values.decode(Int.self, forKey: .partId) {
            self.partId = "\(partId)"
        } else {
            partId = try values.decodeIfPresent(String.self, forKey: .partId) ?? ""
        }
        mimeType = try values.decode(String.self, forKey: .mimeType)
        encoding = try values.decodeIfPresent(String.self, forKey: .encoding)
        size = try values.decode(Int.self, forKey: .size)
        name = try values.decode(String.self, forKey: .name)
        disposition = try values.decode(AttachmentDisposition.self, forKey: .disposition)
        contentId = try values.decodeIfPresent(String.self, forKey: .contentId)
        resource = try values.decodeIfPresent(String.self, forKey: .resource)
        driveUrl = try values.decodeIfPresent(String.self, forKey: .driveUrl)
    }
    
    override init() {
        super.init()
    }

    public convenience init(
        uuid: String? = nil,
        partId: String,
        mimeType: String,
        encoding: String? = nil,
        size: Int,
        name: String,
        disposition: AttachmentDisposition,
        contentId: String? = nil,
        resource: String? = nil,
        driveUrl: String? = nil,
        data: Data? = nil
    ) {
        self.init()

        self.uuid = uuid
        self.partId = partId
        self.mimeType = mimeType
        self.encoding = encoding
        self.size = size
        self.name = name
        self.disposition = disposition
        self.contentId = contentId
        self.resource = resource
        self.driveUrl = driveUrl
        self.data = data
    }
}

public enum AttachmentDisposition: String, Codable, PersistableEnum {
    case inline, attachment
}
