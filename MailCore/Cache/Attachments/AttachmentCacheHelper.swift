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
import Nuke

struct AttachmentCacheHelper {
    let pipeline: ImagePipeline

    func getCache(resource: String?) -> Data? {
        guard let resource, let resourceURL = URL(string: resource) else { return nil }
        let request = ImageRequest(url: resourceURL)
        return pipeline.cache.cachedData(for: request)
    }

    func storeCache(resource: String?, data: Data) {
        guard let resource, let resourceURL = URL(string: resource) else { return }
        let request = ImageRequest(url: resourceURL)
        pipeline.cache.storeCachedData(data, for: request)
    }
}
