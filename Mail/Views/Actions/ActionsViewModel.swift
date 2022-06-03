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

struct Action: Identifiable {
    let id: Int
    let title: String
    let icon: MailResourcesImages
    let quickAction: Bool
}

@MainActor class ActionsViewModel: ObservableObject {
    let allActions = [
        Action(id: 1, title: "Supprimer", icon: MailResourcesAsset.bin, quickAction: true),
        Action(id: 2, title: "Répondre", icon: MailResourcesAsset.emailActionReply, quickAction: true),
        Action(id: 3, title: "Archiver", icon: MailResourcesAsset.archives, quickAction: true),
        Action(id: 4, title: "Transférer", icon: MailResourcesAsset.emailActionTransfer, quickAction: true),
        Action(id: 5, title: "Marquer comme lu", icon: MailResourcesAsset.envelope, quickAction: false),
        Action(id: 6, title: "Déplacer", icon: MailResourcesAsset.emailActionSend21, quickAction: false),
        Action(id: 7, title: "Reporter", icon: MailResourcesAsset.waitingMessage, quickAction: false),
        Action(id: 8, title: "Spam", icon: MailResourcesAsset.spam, quickAction: false),
        Action(id: 9, title: "Bloquer l’expéditeur", icon: MailResourcesAsset.blockUser, quickAction: false),
        Action(id: 10, title: "Hammeçonnage", icon: MailResourcesAsset.fishing, quickAction: false),
        Action(id: 11, title: "Imprimer", icon: MailResourcesAsset.printText, quickAction: false),
        Action(id: 12, title: "Enregistrer en PDF", icon: MailResourcesAsset.fileDownload, quickAction: false),
        Action(id: 13, title: "Ouvrir dans", icon: MailResourcesAsset.sendTo, quickAction: false),
        Action(id: 14, title: "Créer une règle", icon: MailResourcesAsset.ruleRegle, quickAction: false),
        Action(id: 15, title: "Signaler un problème d’affichage", icon: MailResourcesAsset.feedbacks, quickAction: false),
        Action(id: 16, title: "Modifier le menu", icon: MailResourcesAsset.editTools, quickAction: false)
    ]

    var quickActions: [Action] {
        allActions.filter(\.quickAction)
    }

    var actions: [Action] {
        Array(allActions.drop(while: \.quickAction))
    }
}
