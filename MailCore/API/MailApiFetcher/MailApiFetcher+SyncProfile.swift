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

import Alamofire
import Foundation
import InfomaniakCore

public extension MailApiFetcher {
    func downloadSyncProfile(syncContacts: Bool, syncCalendar: Bool) async throws -> URL {
        let destination = DownloadRequest.suggestedDownloadDestination(options: [
            .createIntermediateDirectories,
            .removePreviousFile
        ])
        let download = authenticatedSession.download(
            Endpoint.downloadSyncProfile(syncContacts: syncContacts, syncCalendar: syncCalendar).url,
            to: destination
        )
        return try await download.serializingDownloadedFileURL().value
    }

    func applicationPassword() async throws -> ApplicationPassword {
        /* try await perform(request: authenticatedRequest(
             .applicationPassword,
             method: .post
         )).data */
        return ApplicationPassword(password: "test")
    }
}
