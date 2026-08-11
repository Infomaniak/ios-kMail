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
import RealmSwift

public final class MailTemplate: Object, Codable, ObjectKeyIdentifiable {
    @Persisted(primaryKey: true) public var id: Int
    @Persisted public var title = ""
    @Persisted public var bodyData: Data?
    @Persisted public var attachments: List<Attachment>
    @Persisted public var date = Date()

    public var body: String {
        get {
            guard let decompressedString = bodyData?.decompressedString() else {
                return ""
            }

            return decompressedString
        } set {
            guard let data = newValue.compressed() else {
                bodyData = nil
                return
            }

            bodyData = data
        }
    }

    public var displayName: String {
        title.isEmpty ? "Modèle sans nom" : title
    }

    public var inlineImages: [Attachment] {
        attachments.filter { $0.disposition == .inline }
    }

    override public init() {}

    public convenience init(id: Int,
                            title: String,
                            body: String,
                            attachments: [Attachment] = [],
                            date: Date = Date()) {
        self.init()
        self.id = id
        self.title = title
        self.body = body
        self.attachments = attachments.toRealmList()
        self.date = date
    }
}

public extension MailTemplate {
    static let mocks: [MailTemplate] = [
        MailTemplate(id: 1, title: "Bienvenue",
                     body: "<p>Bienvenue chez nous !</p>"),
        MailTemplate(id: 2, title: "",
                     body: "<p>Corps sans titre</p>"),
        MailTemplate(id: 3, title: "Relance facture",
                     body: "<p>Bonjour, n'oubliez pas de régler la facture.</p>"),
        MailTemplate(id: 4, title: "Réunion",
                     body: "<p><strong>Ordre du jour :</strong></p><ul><li>Point 1</li><li>Point 2</li></ul>"),
    ]
}
