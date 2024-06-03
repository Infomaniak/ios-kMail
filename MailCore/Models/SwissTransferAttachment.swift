/*
 Infomaniak Mail - iOS App
 Copyright (C) 2024 Infomaniak Network SA

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
import RealmSwift
import MailResources

public class SwissTransferAttachment: EmbeddedObject, Codable {
    @Persisted public var uuid: String
    @Persisted public var nbfiles: Int
    @Persisted public var size: Int64
    @Persisted public var files: RealmSwift.List<File>
}

public class File: EmbeddedObject, Codable, Identifiable {
    @Persisted public var uuid: String
    @Persisted public var name: String
    @Persisted public var size: Int64
    @Persisted public var type: String

    public var icon: MailResourcesImages {
        return AttachmentHelper(type: type).icon
    }
}
