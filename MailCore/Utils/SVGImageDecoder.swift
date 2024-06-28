/*
 Infomaniak Mail - iOS App
 Copyright (C) 2024 Infomaniak Network SA

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
import SVGKit

final class SVGImageDecoder: ImageDecoding {
    static func register() {
        ImageDecoderRegistry.shared.register { context in
            let isSVG = context.urlResponse?.mimeType?.contains("svg") ?? false
            return isSVG ? SVGImageDecoder() : nil
        }
    }

    func decode(_ data: Data) throws -> ImageContainer {
        guard let svgImage = SVGKImage(data: data) else {
            throw ImageDecodingError.unknown
        }

        return ImageContainer(image: SVGKExporterUIImage.export(asUIImage: svgImage), data: data)
    }
}
