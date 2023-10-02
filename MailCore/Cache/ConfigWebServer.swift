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

import CocoaLumberjackSwift
import Foundation
import Swifter
import UIKit

public class ConfigWebServer {
    private let server = HttpServer()
    private var firstLoad = true

    public static let syncProfileBackToAppHTML: String = Bundle.main.load(
        filename: "SyncProfileBackToApp",
        withExtension: "html"
    ) ?? ""

    public static let syncProfileIndexHTML: String = Bundle.main.load(
        filename: "SyncProfileIndex",
        withExtension: "html"
    ) ?? ""

    public init() {}

    public func start(
        configURL: URL,
        buttonTitle: String,
        buttonBackgroundColor: UIColor,
        buttonForegroundColor: UIColor,
        backgroundColor: UIColor
    ) {
        firstLoad = true
        server["/install"] = { [weak self] _ in
            if self?.firstLoad == true {
                self?.firstLoad = false
                return .raw(200, "OK", ["Content-Type": "application/x-apple-aspen-config"]) { writer in
                    do {
                        let configData = try Data(contentsOf: configURL)
                        try writer.write(configData)
                    } catch {
                        DDLogError("Failed to write config \(error)")
                    }
                }
            } else {
                return .ok(.html(ConfigWebServer.syncProfileBackToAppHTML
                        .replacingOccurrences(of: "{buttonTitle}", with: buttonTitle)
                        .replacingOccurrences(of: "{backgroundColor}", with: backgroundColor.hexString)
                        .replacingOccurrences(of: "{buttonBackgroundColor}", with: buttonBackgroundColor.hexString)
                        .replacingOccurrences(of: "{buttonForegroundColor}", with: buttonForegroundColor.hexString)))
            }
        }

        server["/index"] = { [weak self] _ in
            self?.firstLoad = true
            return .ok(.html(ConfigWebServer.syncProfileIndexHTML))
        }

        do {
            try server.start()
        } catch {
            DDLogError("Error starting config server \(error)")
        }
    }

    public func stop() {
        server.stop()
    }
}

private extension UIColor {
    var hexString: String {
        guard let cgColorInRGB = cgColor.converted(
            to: CGColorSpace(name: CGColorSpace.sRGB)!,
            intent: .defaultIntent,
            options: nil
        ) else {
            return ""
        }
        let colorRef = cgColorInRGB.components
        let r = colorRef?[0] ?? 0
        let g = colorRef?[1] ?? 0
        let b = ((colorRef?.count ?? 0) > 2 ? colorRef?[2] : g) ?? 0
        let a = cgColor.alpha

        var color = String(format: "#%02lX%02lX%02lX", lroundf(Float(r * 255)), lroundf(Float(g * 255)), lroundf(Float(b * 255)))

        if a < 1 {
            color += String(format: "%02lX", lroundf(Float(a * 255)))
        }

        return color
    }
}
