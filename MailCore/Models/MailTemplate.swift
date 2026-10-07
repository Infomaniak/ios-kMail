/*
 Infomaniak Mail - iOS App
 Copyright (C) 2025 Infomaniak Network SA

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
import MailResources
import RealmSwift

public final class MailTemplate: Object, Codable, ObjectKeyIdentifiable {
    @Persisted(primaryKey: true) public var id: String
    @Persisted public var title: String
    @Persisted public var preview: String
    @Persisted public var content: String
    @Persisted public var attachments: List<Attachment>
    @Persisted public var date = Date()

    public var displayName: String {
        title.isEmpty ? MailResourcesStrings.Localizable.unnamedModel : title
    }

    public var inlineImages: [Attachment] {
        attachments.filter { $0.disposition == .inline }
    }

    override public init() {}

    public convenience init(id: String,
                            title: String,
                            preview: String,
                            content: String,
                            attachments: [Attachment] = [],
                            date: Date = Date()) {
        self.init()
        self.id = id
        self.title = title
        self.preview = preview
        self.content = content
        self.attachments = attachments.toRealmList()
        self.date = date
    }

    private enum CodingKeys: String, CodingKey {
        case id, title, preview, content
    }

    public required convenience init(from decoder: Decoder) throws {
        self.init()

        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        preview = try container.decode(String.self, forKey: .preview)
        content = try container.decode(String.self, forKey: .content)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(preview, forKey: .preview)
        try container.encode(content, forKey: .content)
    }
}
