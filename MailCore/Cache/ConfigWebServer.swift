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
import Swifter

public class ConfigWebServer {
    private let server = HttpServer()
    private var firstLoad = true
    public init() {}

    public func start(configURL: URL) {
        firstLoad = true
        server["/install"] = { [weak self] _ in
            if self?.firstLoad == true {
                self?.firstLoad = false
                return .raw(200, "OK", ["Content-Type": "application/x-apple-aspen-config"]) { writer in
                    do {
                        let configData = try Data(contentsOf: configURL)
                        try writer.write(configData)
                    } catch {
                        print("Failed to write response data")
                    }
                }
            } else {
                return .ok(.html("""
                <html>
                  <head>
                    <meta charset="UTF-8">
                    <title>Profile Install</title>
                    <meta name="viewport" content="width=device-width, initial-scale=1.0">
                    <style>
                      .custom-button {
                        font-family: -apple-system, Arial, sans-serif;
                        font-size: 16pt;
                        display: inline-block;
                        padding: 20pt;
                        border-radius: 15pt;
                        background-color: #0097FF;
                        color: white;
                        text-decoration: none;
                        font-weight: bold;
                        width: 100%;
                        margin: 32pt;
                        text-align: center;
                      }
                      .whole-body {
                        position: absolute;
                        width: 100%;
                        height: 100%;
                      }
                      body {
                        background-color: #F4F6FD;
                     }
                    </style>
                  </head>
                  <body>
                    <a class="whole-body" href="com.infomaniak.mail.profile-callback://">
                      <a class="custom-button" href="com.infomaniak.mail.profile-callback://">
                        !Revenir sur l’application Mail
                      </a>
                    </a>
                  </body>
                </html>
                """))
            }
        }

        server["/index"] = { [weak self] _ in
            self?.firstLoad = true
            return .ok(.html("""
                             <HTML><HEAD><title>Profile Install</title>\
                             </HEAD><script> \
                             function load() { window.location.href='http://localhost:8080/install'; } \
                var int=self.setInterval(function(){load()},400); \
                </script><BODY></BODY></HTML>
            """))
        }

        do {
            try server.start()
        } catch {
            print(error)
        }
    }

    public func stop() {
        server.stop()
    }
}
