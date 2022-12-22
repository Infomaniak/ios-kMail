//
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

import Lottie
import Foundation

extension AnimationKeypath {
    static func iphoneScreen(group: Int, fond: Int) -> Self {
        return AnimationKeypath(keys: ["IPHONE SCREEN", "Groupe \(group)", "Fond \(fond)"])
    }
}

struct IlluColors {
    let keypath: AnimationKeypath
    let lightColor: String
    let darkColor: String

    static let illuColors = [
        IlluColors(keypath: .iphoneScreen(group: 18, fond: 1), lightColor: "#F5F5F5", darkColor: "#3E3E3E"),
        IlluColors(keypath: .iphoneScreen(group: 22, fond: 1), lightColor: "#E0E0E0", darkColor: "#4C4C4C"),
        IlluColors(keypath: .iphoneScreen(group: 25, fond: 1), lightColor: "#E0E0E0", darkColor: "#4C4C4C"),
        IlluColors(keypath: .iphoneScreen(group: 26, fond: 1), lightColor: "#FAFAFA", darkColor: "#282828"),
        IlluColors(keypath: .iphoneScreen(group: 27, fond: 1), lightColor: "#E0E0E0", darkColor: "#4C4C4C"),
        IlluColors(keypath: .iphoneScreen(group: 28, fond: 1), lightColor: "#E0E0E0", darkColor: "#4C4C4C"),
        IlluColors(keypath: .iphoneScreen(group: 29, fond: 1), lightColor: "#E0E0E0", darkColor: "#4C4C4C"),
        IlluColors(keypath: .iphoneScreen(group: 30, fond: 1), lightColor: "#E0E0E0", darkColor: "#4C4C4C"),
        IlluColors(keypath: .iphoneScreen(group: 31, fond: 1), lightColor: "#E0E0E0", darkColor: "#4C4C4C"),
        IlluColors(keypath: .iphoneScreen(group: 32, fond: 1), lightColor: "#E0E0E0", darkColor: "#4C4C4C"),
        IlluColors(keypath: .iphoneScreen(group: 33, fond: 1), lightColor: "#E0E0E0", darkColor: "#4C4C4C"),
        IlluColors(keypath: .iphoneScreen(group: 34, fond: 1), lightColor: "#E0E0E0", darkColor: "#4C4C4C"),
        IlluColors(keypath: .iphoneScreen(group: 35, fond: 1), lightColor: "#E0E0E0", darkColor: "#4C4C4C"),
        IlluColors(keypath: .iphoneScreen(group: 36, fond: 1), lightColor: "#E0E0E0", darkColor: "#4C4C4C"),
        IlluColors(keypath: .iphoneScreen(group: 37, fond: 1), lightColor: "#E0E0E0", darkColor: "#4C4C4C"),
        IlluColors(keypath: .iphoneScreen(group: 38, fond: 1), lightColor: "#E0E0E0", darkColor: "#4C4C4C"),
        IlluColors(keypath: .iphoneScreen(group: 39, fond: 1), lightColor: "#C6AC9F", darkColor: "#996452"),
        IlluColors(keypath: .iphoneScreen(group: 44, fond: 1), lightColor: "#F5F5F5", darkColor: "#3E3E3E"),
        IlluColors(keypath: .iphoneScreen(group: 49, fond: 1), lightColor: "#C6AC9F", darkColor: "#996452"),
        IlluColors(keypath: .iphoneScreen(group: 50, fond: 1), lightColor: "#F5F5F5", darkColor: "#3E3E3E"),
        IlluColors(keypath: .iphoneScreen(group: 62, fond: 1), lightColor: "#F5F5F5", darkColor: "#3E3E3E"),
        IlluColors(keypath: .iphoneScreen(group: 68, fond: 1), lightColor: "#F5F5F5", darkColor: "#3E3E3E"),
        IlluColors(keypath: .iphoneScreen(group: 70, fond: 1), lightColor: "#F5F5F5", darkColor: "#3E3E3E")
    ]
}
