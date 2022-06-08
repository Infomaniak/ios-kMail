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
import MailCore
import MailResources

struct Action: Identifiable {
    let id: Int
    let title: String
    let icon: MailResourcesImages

    static let delete = Action(id: 1, title: MailResourcesStrings.buttonDelete, icon: MailResourcesAsset.bin)
    static let reply = Action(id: 2, title: MailResourcesStrings.buttonReply, icon: MailResourcesAsset.emailActionReply)
    static let archive = Action(id: 3, title: MailResourcesStrings.buttonArchive, icon: MailResourcesAsset.archives)
    static let forward = Action(id: 4, title: MailResourcesStrings.buttonForward, icon: MailResourcesAsset.emailActionTransfer)
    static let markAsRead = Action(id: 5, title: MailResourcesStrings.buttonMarkAsRead, icon: MailResourcesAsset.envelope)
    static let move = Action(id: 6, title: MailResourcesStrings.buttonMove, icon: MailResourcesAsset.emailActionSend21)
    static let postpone = Action(id: 7, title: MailResourcesStrings.buttonPostpone, icon: MailResourcesAsset.waitingMessage)
    static let spam = Action(id: 8, title: MailResourcesStrings.buttonSpam, icon: MailResourcesAsset.spam)
    static let block = Action(id: 9, title: MailResourcesStrings.buttonBlockSender, icon: MailResourcesAsset.blockUser)
    static let phishing = Action(id: 10, title: MailResourcesStrings.buttonPhishing, icon: MailResourcesAsset.fishing)
    static let print = Action(id: 11, title: MailResourcesStrings.buttonPrint, icon: MailResourcesAsset.printText)
    static let saveAsPDF = Action(id: 12, title: MailResourcesStrings.buttonSavePDF, icon: MailResourcesAsset.fileDownload)
    static let openIn = Action(id: 13, title: MailResourcesStrings.buttonOpenIn, icon: MailResourcesAsset.sendTo)
    static let createRule = Action(id: 14, title: MailResourcesStrings.buttonCreateRule, icon: MailResourcesAsset.ruleRegle)
    static let report = Action(id: 15, title: MailResourcesStrings.buttonReportDisplayProblem, icon: MailResourcesAsset.feedbacks)
    static let editMenu = Action(id: 16, title: MailResourcesStrings.buttonEditMenu, icon: MailResourcesAsset.editTools)
}

enum ActionsTarget: Equatable {
    case threads([Thread])
    case thread(Thread)
    case message(Message)
}

@MainActor class ActionsViewModel: ObservableObject {
    let target: ActionsTarget
    @Published var quickActions: [Action] = []
    @Published var listActions: [Action] = []

    init(target: ActionsTarget) {
        self.target = target
        setActions()
    }

    private func setActions() {
        // In the future, we might want to adjust the actions based on the target
        quickActions = [.delete, .reply, .archive, .forward]
        listActions = [
            .markAsRead,
            .move,
            .postpone,
            .spam,
            .block,
            .phishing,
            .print,
            .saveAsPDF,
            .openIn,
            .createRule,
            .report,
            .editMenu
        ]
    }

    func didTap(action: Action) {
        // TODO: Handle action
        print("Did tap on action: \"\(action.title)\"")
    }
}
