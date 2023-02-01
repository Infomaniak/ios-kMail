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
import Lottie
import UIKit

extension AnimationKeypath {
    enum Category: String {
        case archives = "ARCHIVES"
        case bin = "BIN"
        case chat = "CHAT"
        case clock = "CLOCK"
        case hand = "HAND"
        case iPhoneScreen = "IPHONE SCREEN"
        case letter = "LETTER"
        case link = "LINK"
        case men = "MEN"
        case movingNotification = "MOVING NOTIF"
        case notification = "NOTIFICATION"
        case point = "POINT"
        case star = "STAR"
        case woman = "WOMAN"
    }

    enum FinalLayer: String {
        case background = "Fond"
        case border = "Contour"
    }

    static func keyPath(category: Category, categoryNumber: Int? = nil, group: Int = 1, finalLayer: FinalLayer = .background) -> Self {
        var categoryName = category.rawValue
        if let categoryNumber {
            categoryName = "\(categoryName) \(categoryNumber)"
        }
        return AnimationKeypath(keys: [categoryName, "Groupe \(group)", "\(finalLayer.rawValue) 1", "Color"])
    }
}

struct IlluColors {
    let keyPath: AnimationKeypath
    let colors: Colors

    init(_ keyPath: AnimationKeypath, colors: Colors) {
        self.keyPath = keyPath
        self.colors = colors
    }

    struct Colors {
        let lightColor: UIColor
        let darkColor: UIColor

        init(lightColor: String, darkColor: String) {
            self.lightColor = UIColor(hex: lightColor)!
            self.darkColor = UIColor(hex: darkColor)!
        }

        static let commonColors1 = Colors(lightColor: "#F5F5F5", darkColor: "#3E3E3E")
        static let commonColors2 = Colors(lightColor: "#E0E0E0", darkColor: "#4C4C4C")
        static let commonColors3 = Colors(lightColor: "#FAFAFA", darkColor: "#282828")
        static let commonColors4 = Colors(lightColor: "#C6AC9F", darkColor: "#996452")
        static let commonColors5 = Colors(lightColor: "#FFFFFF", darkColor: "#1A1A1A")
        static let commonColors6 = Colors(lightColor: "#340E00", darkColor: "#996452")
        static let commonColors7 = Colors(lightColor: "#CCCCCC", darkColor: "#818181")
        static let commonColors8 = Colors(lightColor: "#C4C4C4", darkColor: "#7C7C7C")
        static let commonColors9 = Colors(lightColor: "#FFFFFF", darkColor: "#EAEAEA")
        static let commonColors10 = Colors(lightColor: "#F8F8F8", darkColor: "#E4E4E4")
        static let commonColors11 = Colors(lightColor: "#D9D9D9", darkColor: "#626262")

        static let pinkColors1 = Colors(lightColor: "#BC0055", darkColor: "#D0759F")
        static let pinkColors2 = Colors(lightColor: "#FF5B97", darkColor: "#EF0057")
        static let pinkColors3 = Colors(lightColor: "#AB2456", darkColor: "#D0759F")
        static let pinkColors4 = Colors(lightColor: "#BD95A7", darkColor: "#AE366D")
        static let pinkColors5 = Colors(lightColor: "#BF4C80", darkColor: "#E75F9C")
        static let pinkColors6 = Colors(lightColor: "#DFBDCC", darkColor: "#955873")
        static let pinkColors7 = Colors(lightColor: "#824D65", darkColor: "#AB6685")
        static let pinkColors8 = Colors(lightColor: "#693D51", darkColor: "#CA799E")
        static let pinkColors9 = Colors(lightColor: "#F7E8EF", darkColor: "#282828")
        static let pinkColors10 = Colors(lightColor: "#FF4388", darkColor: "#B80043")
        static let pinkColors11 = Colors(lightColor: "#D81B60", darkColor: "#FB2C77")
        static let pinkColors12 = Colors(lightColor: "#FAF0F0", darkColor: "#F1DDDD")
        static let pinkColors13 = Colors(lightColor: "#E10B59", darkColor: "#DC1A60")

        static let blueColors1 = Colors(lightColor: "#0098FF", darkColor: "#0177C7")
        static let blueColors2 = Colors(lightColor: "#69C9FF", darkColor: "#6DCBFF")
        static let blueColors3 = Colors(lightColor: "#3981AA", darkColor: "#56AFE1")
        static let blueColors4 = Colors(lightColor: "#289CDD", darkColor: "#0D7DBC")
        static let blueColors5 = Colors(lightColor: "#84BAD8", darkColor: "#588EAC")
        static let blueColors6 = Colors(lightColor: "#10405B", darkColor: "#10405B")
        static let blueColors7 = Colors(lightColor: "#0B3547", darkColor: "#266E8D")
        static let blueColors8 = Colors(lightColor: "#EAF8FE", darkColor: "#282828")
        static let blueColors9 = Colors(lightColor: "#0A85C9", darkColor: "#0A85C9")
        static let blueColors10 = Colors(lightColor: "#F7FCFF", darkColor: "#E8F6FF")
        static let blueColors11 = Colors(lightColor: "#0875A5", darkColor: "#0875A5")
    }
}

// MARK: - Onboarding colors

extension IlluColors {
    // MARK: Default colors

    static let onBoardingAllColors = [
        IlluColors(.keyPath(category: .iPhoneScreen, group: 18), colors: .commonColors1),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 22), colors: .commonColors2),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 25), colors: .commonColors2),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 26), colors: .commonColors3),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 27), colors: .commonColors2),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 28), colors: .commonColors2),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 29), colors: .commonColors2),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 30), colors: .commonColors2),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 31), colors: .commonColors2),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 32), colors: .commonColors2),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 33), colors: .commonColors2),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 34), colors: .commonColors2),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 35), colors: .commonColors2),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 36), colors: .commonColors2),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 37), colors: .commonColors2),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 38), colors: .commonColors2),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 39), colors: .commonColors4),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 44), colors: .commonColors1),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 49), colors: .commonColors4),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 50), colors: .commonColors1),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 62), colors: .commonColors1),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 68), colors: .commonColors1),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 70), colors: .commonColors1)
    ]

    // MARK: Theme colors

    static let onBoardingPinkColors = [
        IlluColors(.keyPath(category: .iPhoneScreen, group: 1), colors: .pinkColors1),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 2), colors: .pinkColors1),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 3), colors: .pinkColors1),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 4), colors: .pinkColors1),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 5), colors: .pinkColors1),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 6), colors: .pinkColors1),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 9), colors: .pinkColors2),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 12), colors: .pinkColors3),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 15), colors: .pinkColors1),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 19), colors: .pinkColors1),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 20), colors: .pinkColors1),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 23), colors: .pinkColors1),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 24), colors: .pinkColors1),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 43), colors: .pinkColors4),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 48), colors: .pinkColors5)
    ]

    static let onBoardingBlueColors = [
        IlluColors(.keyPath(category: .iPhoneScreen, group: 1), colors: .blueColors1),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 2), colors: .blueColors1),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 3), colors: .blueColors1),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 4), colors: .blueColors1),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 5), colors: .blueColors1),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 6), colors: .blueColors1),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 9), colors: .blueColors2),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 12), colors: .blueColors1),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 15), colors: .blueColors1),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 19), colors: .blueColors1),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 20), colors: .blueColors1),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 23), colors: .blueColors1),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 24), colors: .blueColors1),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 43), colors: .blueColors3),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 48), colors: .blueColors4)
    ]

    // MARK: Each illustration

    static let illuOnBoarding1Colors = [
        IlluColors(.keyPath(category: .point, categoryNumber: 1), colors: .commonColors5),
        IlluColors(.keyPath(category: .point, categoryNumber: 2), colors: .commonColors5),
        IlluColors(.keyPath(category: .point, categoryNumber: 3), colors: .commonColors5),
        IlluColors(.keyPath(category: .point, categoryNumber: 4), colors: .commonColors5),
        IlluColors(.keyPath(category: .point, categoryNumber: 5), colors: .commonColors5),
        IlluColors(.keyPath(category: .point, categoryNumber: 6), colors: .commonColors5),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 56), colors: .commonColors1),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 67), colors: .commonColors6),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 69), colors: .commonColors5)
    ]
    static let illuOnBoarding1PinkColors = [
        IlluColors(.keyPath(category: .chat, categoryNumber: 1), colors: .pinkColors1),
        IlluColors(.keyPath(category: .chat, categoryNumber: 2), colors: .pinkColors4),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 55), colors: .pinkColors6),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 61), colors: .pinkColors1),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 66), colors: .pinkColors7)
    ]
    static let illuOnBoarding1BlueColors = [
        IlluColors(.keyPath(category: .chat, categoryNumber: 1), colors: .blueColors1),
        IlluColors(.keyPath(category: .chat, categoryNumber: 2), colors: .blueColors3),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 55), colors: .blueColors5),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 61), colors: .blueColors1),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 66), colors: .blueColors6)
    ]

    static let illuOnBoarding2Colors = [
        IlluColors(.keyPath(category: .notification, categoryNumber: 2, group: 5), colors: .commonColors4),
        IlluColors(.keyPath(category: .notification, categoryNumber: 2, group: 6), colors: .commonColors1),
        IlluColors(.keyPath(category: .notification, categoryNumber: 2, group: 9), colors: .commonColors7),
        IlluColors(.keyPath(category: .notification, categoryNumber: 2, group: 10), colors: .commonColors7),
        IlluColors(.keyPath(category: .notification, categoryNumber: 2, group: 12), colors: .commonColors5),
        IlluColors(.keyPath(category: .notification, categoryNumber: 2, group: 13), colors: .commonColors2),
        IlluColors(.keyPath(category: .notification, categoryNumber: 2, group: 14), colors: .commonColors1),
        IlluColors(.keyPath(category: .movingNotification, categoryNumber: 1, group: 4), colors: .commonColors8),
        IlluColors(.keyPath(category: .movingNotification, categoryNumber: 1, group: 5), colors: .commonColors8),
        IlluColors(.keyPath(category: .movingNotification, categoryNumber: 1, group: 6), colors: .commonColors8),
        IlluColors(.keyPath(category: .movingNotification, categoryNumber: 1, group: 7), colors: .commonColors5),
        IlluColors(.keyPath(category: .movingNotification, categoryNumber: 1, group: 8), colors: .commonColors2),
        IlluColors(.keyPath(category: .movingNotification, categoryNumber: 1, group: 9), colors: .commonColors2),
        IlluColors(.keyPath(category: .movingNotification, categoryNumber: 1, group: 10), colors: .commonColors2),
        IlluColors(.keyPath(category: .movingNotification, categoryNumber: 1, group: 13), colors: .commonColors5),
        IlluColors(.keyPath(category: .movingNotification, categoryNumber: 1, group: 14), colors: .commonColors8),
        IlluColors(.keyPath(category: .movingNotification, categoryNumber: 2, group: 5), colors: .commonColors4),
        IlluColors(.keyPath(category: .movingNotification, categoryNumber: 2, group: 6), colors: .commonColors1),
        IlluColors(.keyPath(category: .movingNotification, categoryNumber: 2, group: 9), colors: .commonColors7),
        IlluColors(.keyPath(category: .movingNotification, categoryNumber: 2, group: 10), colors: .commonColors7),
        IlluColors(.keyPath(category: .movingNotification, categoryNumber: 2, group: 12), colors: .commonColors5),
        IlluColors(.keyPath(category: .movingNotification, categoryNumber: 2, group: 13), colors: .commonColors2),
        IlluColors(.keyPath(category: .movingNotification, categoryNumber: 2, group: 14), colors: .commonColors1),
        IlluColors(.keyPath(category: .movingNotification, categoryNumber: 2, group: 15), colors: .commonColors1),
        IlluColors(AnimationKeypath(keys: ["MOVING NOTIF 2 TITLE", "Groupe 1", "Fond 1", "Color"]), colors: .commonColors2),
        IlluColors(AnimationKeypath(keys: ["MOVING NOTIF 2 PREVIEW", "Groupe 1", "Fond 1", "Color"]), colors: .commonColors2),
        IlluColors(.keyPath(category: .archives, group: 1), colors: .commonColors5),
        IlluColors(.keyPath(category: .archives, group: 2), colors: .commonColors5),
        IlluColors(.keyPath(category: .archives, group: 3), colors: .commonColors5),
        IlluColors(.keyPath(category: .archives, group: 4), colors: .commonColors5)
    ]
    static let illuOnBoarding2PinkColors = [
        IlluColors(.keyPath(category: .notification, categoryNumber: 2, group: 4), colors: .pinkColors5),
        IlluColors(.keyPath(category: .notification, categoryNumber: 2, group: 11), colors: .pinkColors1),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 54), colors: .pinkColors5),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 61), colors: .pinkColors6),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 67), colors: .pinkColors1),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 72), colors: .pinkColors7),
        IlluColors(.keyPath(category: .hand, group: 1), colors: .pinkColors7),
        IlluColors(.keyPath(category: .hand, group: 4), colors: .pinkColors8),
        IlluColors(.keyPath(category: .hand, group: 5), colors: .pinkColors8),
        IlluColors(.keyPath(category: .movingNotification, categoryNumber: 1, group: 15), colors: .pinkColors1),
        IlluColors(.keyPath(category: .movingNotification, categoryNumber: 2, group: 4), colors: .pinkColors5),
        IlluColors(.keyPath(category: .movingNotification, categoryNumber: 2, group: 11), colors: .pinkColors1)
    ]
    static let illuOnBoarding2BlueColors = [
        IlluColors(.keyPath(category: .notification, categoryNumber: 2, group: 4), colors: .blueColors4),
        IlluColors(.keyPath(category: .notification, categoryNumber: 2, group: 11), colors: .blueColors1),
        IlluColors(.keyPath(category: .hand, group: 1), colors: .blueColors6),
        IlluColors(.keyPath(category: .hand, group: 4), colors: .blueColors7),
        IlluColors(.keyPath(category: .hand, group: 5), colors: .blueColors7),
        IlluColors(.keyPath(category: .movingNotification, categoryNumber: 1, group: 15), colors: .blueColors1),
        IlluColors(.keyPath(category: .movingNotification, categoryNumber: 2, group: 4), colors: .blueColors4),
        IlluColors(.keyPath(category: .movingNotification, categoryNumber: 2, group: 11), colors: .blueColors1)
    ]

    static let illuOnBoarding3Colors = [
        IlluColors(.keyPath(category: .notification, categoryNumber: 2, group: 1), colors: .commonColors2),
        IlluColors(.keyPath(category: .notification, categoryNumber: 2, group: 2), colors: .commonColors2),
        IlluColors(.keyPath(category: .notification, categoryNumber: 2, group: 3), colors: .commonColors5),
        IlluColors(.keyPath(category: .notification, categoryNumber: 3, group: 1), colors: .commonColors2),
        IlluColors(.keyPath(category: .notification, categoryNumber: 3, group: 2), colors: .commonColors2),
        IlluColors(.keyPath(category: .notification, categoryNumber: 3, group: 3), colors: .commonColors5),
        IlluColors(.keyPath(category: .notification, categoryNumber: 4, group: 1), colors: .commonColors2),
        IlluColors(.keyPath(category: .notification, categoryNumber: 4, group: 2), colors: .commonColors2),
        IlluColors(.keyPath(category: .notification, categoryNumber: 4, group: 3), colors: .commonColors5),
        IlluColors(.keyPath(category: .star, group: 2), colors: .commonColors3),
        IlluColors(.keyPath(category: .bin, group: 7), colors: .commonColors3),
        IlluColors(.keyPath(category: .clock, group: 5), colors: .commonColors3)
    ]
    static let illu3PinkColors = [
        IlluColors(.keyPath(category: .notification, categoryNumber: 2, group: 4), colors: .pinkColors1),
        IlluColors(.keyPath(category: .notification, categoryNumber: 2, group: 5), colors: .pinkColors9),
        IlluColors(.keyPath(category: .notification, categoryNumber: 3, group: 4), colors: .pinkColors1),
        IlluColors(.keyPath(category: .notification, categoryNumber: 3, group: 5), colors: .pinkColors9),
        IlluColors(.keyPath(category: .notification, categoryNumber: 4, group: 4), colors: .pinkColors1),
        IlluColors(.keyPath(category: .notification, categoryNumber: 4, group: 5), colors: .pinkColors9),
        IlluColors(.keyPath(category: .hand, group: 1), colors: .pinkColors7),
        IlluColors(.keyPath(category: .hand, group: 4), colors: .pinkColors8),
        IlluColors(.keyPath(category: .hand, group: 5), colors: .pinkColors8),
        IlluColors(.keyPath(category: .star, group: 1, finalLayer: .border), colors: .pinkColors1),
        IlluColors(.keyPath(category: .bin, group: 1, finalLayer: .border), colors: .pinkColors1),
        IlluColors(.keyPath(category: .bin, group: 2, finalLayer: .border), colors: .pinkColors1),
        IlluColors(.keyPath(category: .bin, group: 3, finalLayer: .border), colors: .pinkColors1),
        IlluColors(.keyPath(category: .bin, group: 4, finalLayer: .border), colors: .pinkColors1),
        IlluColors(.keyPath(category: .bin, group: 5, finalLayer: .border), colors: .pinkColors1),
        IlluColors(.keyPath(category: .bin, group: 6, finalLayer: .border), colors: .pinkColors1),
        IlluColors(.keyPath(category: .clock, group: 1), colors: .pinkColors1),
        IlluColors(.keyPath(category: .clock, group: 2), colors: .pinkColors1),
        IlluColors(.keyPath(category: .clock, group: 3), colors: .pinkColors1),
        IlluColors(.keyPath(category: .clock, group: 4), colors: .pinkColors1)
    ]
    static let illu3BlueColors = [
        IlluColors(.keyPath(category: .notification, categoryNumber: 2, group: 4), colors: .blueColors1),
        IlluColors(.keyPath(category: .notification, categoryNumber: 2, group: 5), colors: .blueColors8),
        IlluColors(.keyPath(category: .notification, categoryNumber: 3, group: 4), colors: .blueColors1),
        IlluColors(.keyPath(category: .notification, categoryNumber: 3, group: 5), colors: .blueColors8),
        IlluColors(.keyPath(category: .notification, categoryNumber: 4, group: 4), colors: .blueColors1),
        IlluColors(.keyPath(category: .notification, categoryNumber: 4, group: 5), colors: .blueColors8),
        IlluColors(.keyPath(category: .hand, group: 1), colors: .blueColors6),
        IlluColors(.keyPath(category: .hand, group: 4), colors: .blueColors7),
        IlluColors(.keyPath(category: .hand, group: 5), colors: .blueColors7),
        IlluColors(.keyPath(category: .star, group: 1, finalLayer: .border), colors: .blueColors1),
        IlluColors(.keyPath(category: .bin, group: 1, finalLayer: .border), colors: .blueColors1),
        IlluColors(.keyPath(category: .bin, group: 2, finalLayer: .border), colors: .blueColors1),
        IlluColors(.keyPath(category: .bin, group: 3, finalLayer: .border), colors: .blueColors1),
        IlluColors(.keyPath(category: .bin, group: 4, finalLayer: .border), colors: .blueColors1),
        IlluColors(.keyPath(category: .bin, group: 5, finalLayer: .border), colors: .blueColors1),
        IlluColors(.keyPath(category: .bin, group: 6, finalLayer: .border), colors: .blueColors1),
        IlluColors(.keyPath(category: .clock, group: 1), colors: .blueColors1),
        IlluColors(.keyPath(category: .clock, group: 2), colors: .blueColors1),
        IlluColors(.keyPath(category: .clock, group: 3), colors: .blueColors1),
        IlluColors(.keyPath(category: .clock, group: 4), colors: .blueColors1)
    ]

    static let illuOnBoarding4Colors = [
        IlluColors(.keyPath(category: .woman, group: 5), colors: .commonColors4),
        IlluColors(.keyPath(category: .woman, group: 6), colors: .commonColors1),
        IlluColors(.keyPath(category: .men, group: 5), colors: .commonColors4),
        IlluColors(.keyPath(category: .men, group: 6), colors: .commonColors1),
        IlluColors(.keyPath(category: .letter, group: 3), colors: .commonColors9),
        IlluColors(.keyPath(category: .letter, group: 4), colors: .commonColors10)
    ]
    static let illuOnBoarding4PinkColors = [
        IlluColors(.keyPath(category: .woman, group: 4), colors: .pinkColors5),
        IlluColors(.keyPath(category: .men, group: 5), colors: .pinkColors4),
        IlluColors(.keyPath(category: .point, categoryNumber: 1), colors: .pinkColors5),
        IlluColors(.keyPath(category: .point, categoryNumber: 2), colors: .pinkColors5),
        IlluColors(.keyPath(category: .point, categoryNumber: 3), colors: .pinkColors4),
        IlluColors(.keyPath(category: .point, categoryNumber: 4), colors: .pinkColors4),
        IlluColors(.keyPath(category: .letter, group: 1), colors: .pinkColors10),
        IlluColors(.keyPath(category: .letter, group: 2), colors: .pinkColors11),
        IlluColors(.keyPath(category: .letter, group: 5), colors: .pinkColors12),
        IlluColors(.keyPath(category: .letter, group: 6), colors: .pinkColors13),
        IlluColors(.keyPath(category: .letter, group: 7), colors: .pinkColors13)
    ]
    static let illuOnBoarding4BlueColors = [
        IlluColors(.keyPath(category: .woman, group: 4), colors: .blueColors4),
        IlluColors(.keyPath(category: .men, group: 5), colors: .blueColors3),
        IlluColors(.keyPath(category: .point, categoryNumber: 1), colors: .blueColors4),
        IlluColors(.keyPath(category: .point, categoryNumber: 2), colors: .blueColors4),
        IlluColors(.keyPath(category: .point, categoryNumber: 3), colors: .blueColors3),
        IlluColors(.keyPath(category: .point, categoryNumber: 4), colors: .blueColors3),
        IlluColors(.keyPath(category: .letter, group: 1), colors: .blueColors2),
        IlluColors(.keyPath(category: .letter, group: 2), colors: .blueColors9),
        IlluColors(.keyPath(category: .letter, group: 5), colors: .blueColors10),
        IlluColors(.keyPath(category: .letter, group: 6), colors: .blueColors11),
        IlluColors(.keyPath(category: .letter, group: 7), colors: .blueColors11)
    ]

    // MARK: Several illustrations

    static let illuOnBoarding234Colors = [
        IlluColors(.keyPath(category: .iPhoneScreen, group: 73), colors: .commonColors6),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 74), colors: .commonColors1),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 75), colors: .commonColors5),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 76), colors: .commonColors2)
    ]
    static let illuOnBoarding234PinkColors = [
        IlluColors(.keyPath(category: .iPhoneScreen, group: 54), colors: .pinkColors5),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 61), colors: .pinkColors6),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 67), colors: .pinkColors1),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 72), colors: .pinkColors7)
    ]
    static let illuOnBoarding234BlueColors = [
        IlluColors(.keyPath(category: .iPhoneScreen, group: 54), colors: .blueColors4),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 61), colors: .blueColors5),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 67), colors: .blueColors1),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 72), colors: .blueColors6)
    ]
}

// MARK: - No Mailbox colors

extension IlluColors {
    static let noMailboxAllColors = [
        IlluColors(.keyPath(category: .link), colors: .commonColors11),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 1), colors: .commonColors5),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 2), colors: .commonColors2)
    ]

    static let illuNoMailboxPinkColors = [
        IlluColors(.keyPath(category: .hand, group: 1), colors: .pinkColors7),
        IlluColors(.keyPath(category: .hand, group: 4), colors: .pinkColors8),
        IlluColors(.keyPath(category: .hand, group: 5), colors: .pinkColors8)
    ]

    static let illuNoMailboxBlueColors = [
        IlluColors(.keyPath(category: .hand, group: 1), colors: .blueColors6),
        IlluColors(.keyPath(category: .hand, group: 4), colors: .blueColors7),
        IlluColors(.keyPath(category: .hand, group: 5), colors: .blueColors7)
    ]
}

// MARK: - Functions

extension IlluColors {
    func applyColors(to animation: LottieAnimationView) {
        animation.updateColor(color: colors.lightColor, darkColor: colors.darkColor, for: keyPath)
    }
}
