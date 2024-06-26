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

import Foundation
import InfomaniakCore

public class ApiResponse<ResponseContent: Decodable>: Decodable {
    public let result: ApiResult
    public let data: ResponseContent?
    public let error: ApiError?
    public let total: Int?
    public let pages: Int?
    public let page: Int?
    public let itemsPerPage: Int?
    public let responseAt: Int?

    enum CodingKeys: String, CodingKey {
        case result
        case data
        case error
        case total
        case pages
        case page
        case itemsPerPage = "items_per_page"
        case responseAt = "response_at"
    }
}
