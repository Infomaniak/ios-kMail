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
import SwiftUI

public struct URLConstants {
    public static let feedback = URLConstants(urlString: "https://feedback.userreport.com/9f60b46d-7299-4887-b79d-c756cf474c4d#ideas/popular")
    public static let importMails = URLConstants(urlString: "https://import-email.infomaniak.com")
    public static let matomo = URLConstants(urlString: "https://analytics.infomaniak.com/matomo.php")
    public static let support = URLConstants(urlString: "https://support.infomaniak.com")

    private var urlString: String

    public var url: URL {
        guard let url = URL(string: urlString) else {
            fatalError("Invalid URL")
        }
        return url
    }
}

public enum Constants {
    public static let sizeLimit: Int64 = 20_000_000_000 // 20 Go

	public static let menuDrawerFolderCellPadding: CGFloat = 4

    public static let byteCountFormatterStyle = ByteCountFormatStyle.byteCount(style: .file)

    private static var dateFormatter = DateFormatter()

	public enum DateTimeStyle {
        case date
        case time
        case datetime
    }

    public static func formatDate(_ date: Date, style: DateTimeStyle = .datetime, relative: Bool = false) -> String {
        switch style {
        case .date:
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .none
        case .time:
            dateFormatter.dateStyle = .none
            dateFormatter.timeStyle = .short
        case .datetime:
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .short
        }
        dateFormatter.doesRelativeDateFormatting = relative
        return dateFormatter.string(from: date)
    }

    public static func formatAttachmentSize(_ size: Int64, unit: Bool = true) -> String {
        let byteCountFormatter = ByteCountFormatter()
        byteCountFormatter.countStyle = .binary
        byteCountFormatter.includesUnit = unit
        return byteCountFormatter.string(fromByteCount: size)
    }
}
